import SwiftUI
import MindEchoCore
#if canImport(PhotosUI)
import PhotosUI
#endif

/// 知识采集 ViewModel
/// 管理手动录入、OCR 识别、文档导入的完整流程
@MainActor
final class KnowledgeCaptureViewModel: ObservableObject {
    // MARK: - 采集状态
    @Published var selectedTab: CaptureTab = .manual
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - 手动录入
    @Published var manualTitle = ""
    @Published var manualContent = ""
    @Published var manualTags: [String] = []
    @Published var manualTagText = ""
    @Published var manualCategory: KnowledgeCategory = .concept

    // MARK: - OCR
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var ocrResultText = ""
    @Published var ocrCandidates: [OCRService.KnowledgeCandidate] = []

    // MARK: - 文档导入
    @Published var selectedFileURL: URL?
    @Published var documentText = ""
    @Published var documentFileName = ""

    // MARK: - AI 解析结果
    @Published var parsedNodes: [KnowledgeNode] = []
    @Published var parsedRelations: [AIKnowledgeParser.Relation] = []
    @Published var showParseResult = false

    // MARK: - 保存的知识节点
    @Published var savedNodes: [KnowledgeNode] = []

    private let ocrService = OCRService()
    private let parser = AIKnowledgeParser()

    // MARK: - 手动添加标签
    func addTag() {
        let tag = manualTagText.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty, !manualTags.contains(tag) else { return }
        manualTags.append(tag)
        manualTagText = ""
    }

    func removeTag(_ tag: String) {
        manualTags.removeAll { $0 == tag }
    }

    // MARK: - 手动保存并解析
    func saveManualEntry() async {
        guard !manualTitle.isEmpty, !manualContent.isEmpty else {
            errorMessage = "标题和内容不能为空"
            return
        }

        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        do {
            // 如果用户没填标签，自动生成
            let tags = manualTags.isEmpty ?
                parser.generateTags(for: manualContent) : manualTags

            let node = KnowledgeNode(
                id: UUID(),
                title: manualTitle,
                content: manualContent,
                tags: tags,
                category: manualCategory,
                difficulty: parser.evaluateDifficulty(content: manualContent, tags: tags),
                createdAt: Date(),
                lastReviewedAt: nil,
                reviewCount: 0,
                relatedNodes: [],
                forgettingCurve: nil,
                masteryLevel: 0.0,
                sm2Data: KnowledgeNode.SM2Data(),
                reviewHistory: []
            )

            // AI 解析关联
            let relations = parser.discoverRelations(among: savedNodes + [node])
            let nodeRelations = relations.filter { $0.sourceId == node.id || $0.targetId == node.id }
            var enriched = node
            enriched.relatedNodes = nodeRelations.map { rel in
                let targetId = rel.sourceId == node.id ? rel.targetId : rel.sourceId
                return KnowledgeNode.RelatedNode(nodeId: targetId, relationship: rel.type, strength: rel.strength)
            }

            savedNodes.append(enriched)
            parsedNodes = [enriched]
            parsedRelations = nodeRelations
            showParseResult = true
            clearManualForm()
            successMessage = "知识点「\(enriched.title)」已保存"
        }
    }

    // MARK: - OCR 识别
    func runOCR() async {
        guard selectedPhotoItem != nil else {
            errorMessage = "请先选择图片"
            return
        }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        do {
            // 模拟 OCR 处理（真实环境需加载图片数据）
            let sampleText = """
            机器学习是人工智能的一个分支，
            它使用算法从数据中学习模式。
            监督学习需要标注数据训练模型。
            """
            ocrResultText = sampleText

            // 提取知识点
            ocrCandidates = try await ocrService.extractKnowledgeNodes(from: sampleText)
            if !ocrCandidates.isEmpty {
                successMessage = "识别出 \(ocrCandidates.count) 个知识点候选"
            } else {
                errorMessage = "未识别到有效知识点"
            }
        } catch {
            errorMessage = "OCR 识别失败: \(error.localizedDescription)"
        }
    }

    func importOCRCandidate(_ candidate: OCRService.KnowledgeCandidate) {
        let node = KnowledgeNode(
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
            masteryLevel: candidate.confidence * 0.3, // 初始掌握度基于置信度
            sm2Data: KnowledgeNode.SM2Data(),
            reviewHistory: []
        )
        savedNodes.append(node)
        successMessage = "已导入: \(node.title)"
    }

    func importAllOCRCandidates() {
        for candidate in ocrCandidates {
            importOCRCandidate(candidate)
        }
        ocrCandidates = []
    }

    // MARK: - 文档导入
    func loadDocument(url: URL) {
        selectedFileURL = url
        documentFileName = url.lastPathComponent

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            documentText = text
            successMessage = "已加载: \(documentFileName)"
        } catch {
            // 尝试其他编码
            do {
                let text = try String(contentsOf: url, encoding: .utf16)
                documentText = text
                successMessage = "已加载: \(documentFileName)"
            } catch {
                errorMessage = "无法读取文件，请确保为 TXT/Markdown 格式"
            }
        }
    }

    func parseDocument() async {
        guard !documentText.isEmpty else {
            errorMessage = "请先加载文档"
            return
        }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await parser.parse(text: documentText)
            parsedNodes = result.nodes
            parsedRelations = result.relations
            showParseResult = true
            successMessage = "解析出 \(result.nodes.count) 个知识点"
        } catch {
            errorMessage = "文档解析失败: \(error.localizedDescription)"
        }
    }

    func importAllParsedNodes() {
        for var node in parsedNodes {
            let relations = parsedRelations.filter {
                $0.sourceId == node.id || $0.targetId == node.id
            }
            node.relatedNodes = relations.map { rel in
                let target = rel.sourceId == node.id ? rel.targetId : rel.sourceId
                return KnowledgeNode.RelatedNode(nodeId: target, relationship: rel.type, strength: rel.strength)
            }
            savedNodes.append(node)
        }
        parsedNodes = []
        parsedRelations = []
        showParseResult = false
        successMessage = "已导入全部知识点"
    }

    // MARK: - 清理
    func clearManualForm() {
        manualTitle = ""
        manualContent = ""
        manualTags = []
        manualTagText = ""
        manualCategory = .concept
    }

    func clearOCR() {
        selectedPhotoItem = nil
        ocrResultText = ""
        ocrCandidates = []
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    enum CaptureTab: String, CaseIterable {
        case manual = "手动"
        case ocr = "OCR"
        case document = "文档"

        var icon: String {
            switch self {
            case .manual: return "pencil"
            case .ocr: return "camera.viewfinder"
            case .document: return "doc.fill"
            }
        }
    }
}
