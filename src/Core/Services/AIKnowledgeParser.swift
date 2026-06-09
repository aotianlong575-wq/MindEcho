import Foundation

/// AI 知识解析服务
/// 负责：知识标签自动生成、知识关联发现、难度评估、知识树构建
public final class AIKnowledgeParser {

    private let ocrService: OCRService
    private let graphEngine: KnowledgeGraphEngine

    public init(ocrService: OCRService = OCRService(),
                graphEngine: KnowledgeGraphEngine = KnowledgeGraphEngine()) {
        self.ocrService = ocrService
        self.graphEngine = graphEngine
    }

    // MARK: - 完整解析 Pipeline
    /// 从原始文本到结构化知识节点的全流程解析
    /// - Parameter text: 原始文本
    /// - Returns: 解析出的知识节点和它们之间的关联
    public func parse(text: String) async throws -> ParseResult {
        // 1. 提取知识候选项
        let candidates = try await ocrService.extractKnowledgeNodes(from: text)

        // 2. 构建知识节点
        let nodes = candidates.map { candidate -> KnowledgeNode in
            KnowledgeNode(
                id: UUID(),
                title: candidate.title,
                content: candidate.content,
                tags: candidate.suggestedTags,
                category: candidate.category,
                difficulty: candidate.difficulty,
                createdAt: Date(),
                lastReviewedAt: nil,
                reviewCount: 0,
                relatedNodes: [],
                forgettingCurve: nil,
                masteryLevel: 0.0,
                sm2Data: KnowledgeNode.SM2Data(),
                reviewHistory: []
            )
        }

        // 3. 发现关联关系
        let relations = discoverRelations(among: nodes)

        // 4. 构建知识树
        var enrichedNodes = nodes
        for i in enrichedNodes.indices {
            let relatedRelations = relations.filter { $0.sourceId == enrichedNodes[i].id }
            enrichedNodes[i].relatedNodes = relatedRelations.map { rel in
                KnowledgeNode.RelatedNode(nodeId: rel.targetId, relationship: rel.type, strength: rel.strength)
            }
        }

        return ParseResult(nodes: enrichedNodes, relations: relations)
    }

    // MARK: - 关联发现
    /// 自动发现知识节点之间的关联关系
    public func discoverRelations(among nodes: [KnowledgeNode]) -> [Relation] {
        var relations: [Relation] = []

        for i in 0..<nodes.count {
            for j in (i+1)..<nodes.count {
                let a = nodes[i], b = nodes[j]

                // 标签重叠度
                let tagOverlap = jaccardSimilarity(Set(a.tags), Set(b.tags))

                // 内容相似度
                let contentSim = cosineTextSimilarity(a.content, b.content)

                // 综合得分
                let score = tagOverlap * 0.5 + contentSim * 0.5

                if score > 0.15 {
                    let type = inferRelationship(from: a, to: b, similarity: score)
                    relations.append(Relation(
                        sourceId: a.id, targetId: b.id,
                        type: type, strength: min(score, 1.0)
                    ))
                }
            }
        }
        return relations
    }

    /// 推断两个知识点之间的关系类型
    public func inferRelationship(from source: KnowledgeNode, to target: KnowledgeNode,
                                   similarity: Double) -> RelationshipType {
        // 同分类且标签高度重叠 → 相关
        if source.category == target.category && similarity > 0.6 {
            return .related
        }
        // 前者难度低于后者 → 可能是前置知识
        if source.difficulty < target.difficulty && similarity > 0.3 {
            return .prerequisite
        }
        // 难度差异大 → 扩展
        if abs(source.difficulty.numericValue - target.difficulty.numericValue) > 0.4 {
            return .extension_
        }
        // 内容对立 → 对比（简化：不同分类且低相似度）
        if source.category != target.category && similarity < 0.3 {
            return .opposite
        }
        return .related
    }

    // MARK: - 难度评估
    /// 综合评估知识内容的难度等级
    public func evaluateDifficulty(content: String, tags: [String]) -> DifficultyLevel {
        let lengthScore: Double
        switch content.count {
        case ..<50:  lengthScore = 0.1
        case ..<200: lengthScore = 0.3
        case ..<500: lengthScore = 0.5
        case ..<1000: lengthScore = 0.7
        default:     lengthScore = 0.9
        }

        let tagComplexity = Double(tags.filter { $0.count > 3 }.count) / Double(max(tags.count, 1))
        let technicalDensity = countTechnicalTerms(content) / Double(max(content.components(separatedBy: " ").count, 1))
        let score = lengthScore * 0.3 + tagComplexity * 0.3 + min(technicalDensity * 5, 1.0) * 0.4

        switch score {
        case ..<0.2: return .beginner
        case ..<0.4: return .elementary
        case ..<0.6: return .intermediate
        case ..<0.8: return .advanced
        default: return .expert
        }
    }

    // MARK: - 标签生成
    /// 自动生成知识标签
    public func generateTags(for text: String, existingNodes: [KnowledgeNode] = []) -> [String] {
        // 从文本提取关键词
        let rawKeywords = ocrService.extractKeywords(from: text)

        // 与已有标签去重 + 合并
        let existingTags = Set(existingNodes.flatMap { $0.tags })
        let newTags = rawKeywords.filter { !existingTags.contains($0) }

        // 限制数量
        return Array(newTags.prefix(8))
    }

    // MARK: - 工具方法
    private func jaccardSimilarity(_ set1: Set<String>, _ set2: Set<String>) -> Double {
        let union = set1.union(set2)
        guard !union.isEmpty else { return 0 }
        return Double(set1.intersection(set2).count) / Double(union.count)
    }

    private func cosineTextSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = text1.lowercased().split(separator: " ").map(String.init)
        let words2 = text2.lowercased().split(separator: " ").map(String.init)
        let allWords = Set(words1 + words2)
        guard !allWords.isEmpty else { return 0 }

        let vec1 = allWords.map { Double(words1.filter { $0 == $0 }.count) }
        let vec2 = allWords.map { Double(words2.filter { $0 == $0 }.count) }

        // 修正：用词频向量
        let freq1 = wordFrequency(words1)
        let freq2 = wordFrequency(words2)
        let keys = Set(freq1.keys).union(freq2.keys)

        var dotProduct = 0.0, mag1 = 0.0, mag2 = 0.0
        for key in keys {
            let v1 = freq1[key] ?? 0
            let v2 = freq2[key] ?? 0
            dotProduct += v1 * v2
            mag1 += v1 * v1
            mag2 += v2 * v2
        }
        let denominator = sqrt(mag1) * sqrt(mag2)
        return denominator > 0 ? dotProduct / denominator : 0
    }

    private func wordFrequency(_ words: [String]) -> [String: Double] {
        var freq: [String: Double] = [:]
        for word in words where word.count > 1 { freq[word, default: 0] += 1 }
        return freq
    }

    private func countTechnicalTerms(_ text: String) -> Double {
        Double(OCRService().extractKeywords(from: text).count)
    }

    // MARK: - 类型
    public struct ParseResult {
        public let nodes: [KnowledgeNode]
        public let relations: [Relation]
    }

    public struct Relation {
        public let sourceId: UUID
        public let targetId: UUID
        public let type: RelationshipType
        public let strength: Double
    }
}
