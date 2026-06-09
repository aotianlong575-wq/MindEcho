import SwiftUI
import MindEchoCore

/// 记忆图谱 ViewModel
/// 驱动图谱渲染、搜索筛选、交互状态
@MainActor
final class MemoryGraphViewModel: ObservableObject {
    // MARK: - 数据
    @Published var nodes: [KnowledgeNode] = []
    @Published var filteredNodes: [GraphNode] = []
    @Published var edges: [GraphEdge] = []

    // MARK: - 搜索与筛选
    @Published var searchText = ""
    @Published var selectedCategory: KnowledgeCategory? = nil
    @Published var selectedDifficulty: DifficultyLevel? = nil
    @Published var selectedRiskLevel: ForgettingCurve.RiskLevel? = nil
    @Published var sortOption: SearchQuery.SortOption = .relevance

    // MARK: - 交互状态
    @Published var selectedNode: KnowledgeNode? = nil
    @Published var showNodeDetail = false
    @Published var highlightedPath: [UUID] = []
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero

    // MARK: - 布局
    @Published var nodePositions: [UUID: CGPoint] = [:]
    @Published var layoutReady = false

    private let graphEngine = KnowledgeGraphEngine()
    private let forgettingEngine = ForgettingCurveEngine.self

    // MARK: - 图节点（UI 层）
    struct GraphNode: Identifiable {
        let id: UUID
        let title: String
        let category: KnowledgeCategory
        let difficulty: DifficultyLevel
        let mastery: Double
        let riskLevel: ForgettingCurve.RiskLevel
        let tagCount: Int
        let relationCount: Int
        let pageRank: Double

        var radius: CGFloat {
            let base = 18.0
            let size = base + Double(relationCount) * 2.0
            return min(max(size, 14), 40)
        }
    }

    // MARK: - 图边
    struct GraphEdge: Identifiable {
        let id = UUID()
        let fromId: UUID
        let toId: UUID
        let relationship: RelationshipType
        let strength: Double
    }

    // MARK: - 加载数据
    func load(nodes: [KnowledgeNode]) {
        self.nodes = nodes
        for node in nodes { graphEngine.addNode(node) }
        for node in nodes {
            for rel in node.relatedNodes {
                graphEngine.addEdge(from: node.id, to: rel.nodeId, weight: rel.strength)
            }
        }
        applyFilters()
    }

    func addNode(_ node: KnowledgeNode) {
        nodes.append(node)
        graphEngine.addNode(node)
        applyFilters()
    }

    // MARK: - 筛选
    func applyFilters() {
        var result = nodes

        // 搜索关键词
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.content.lowercased().contains(query) ||
                $0.tags.contains { $0.lowercased().contains(query) }
            }
        }

        // 分类筛选
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }

        // 难度筛选
        if let diff = selectedDifficulty {
            result = result.filter { $0.difficulty == diff }
        }

        // 风险筛选
        if let risk = selectedRiskLevel {
            result = result.filter {
                $0.forgettingCurve?.riskLevel == risk
            }
        }

        // 排序
        switch sortOption {
        case .relevance: break
        case .newest: result.sort { $0.createdAt > $1.createdAt }
        case .oldest: result.sort { $0.createdAt < $1.createdAt }
        case .masteryLow: result.sort { $0.masteryLevel < $1.masteryLevel }
        case .masteryHigh: result.sort { $0.masteryLevel > $1.masteryLevel }
        case .urgent: result.sort {
            ($0.forgettingCurve?.riskLevel == .critical ? 0 : 1) <
            ($1.forgettingCurve?.riskLevel == .critical ? 0 : 1)
        }
        }

        // 计算 PageRank
        let ranks = graphEngine.pageRank()

        // 构建图结构
        let resultIds = Set(result.map { $0.id })
        filteredNodes = result.map { node in
            let relations = node.relatedNodes.filter { resultIds.contains($0.nodeId) }
            return GraphNode(
                id: node.id,
                title: node.title,
                category: node.category,
                difficulty: node.difficulty,
                mastery: node.masteryLevel,
                riskLevel: node.forgettingCurve?.riskLevel ?? .moderate,
                tagCount: node.tags.count,
                relationCount: relations.count,
                pageRank: ranks[node.id] ?? 0
            )
        }

        edges = result.flatMap { node in
            node.relatedNodes
                .filter { resultIds.contains($0.nodeId) }
                .map { GraphEdge(fromId: node.id, toId: $0.nodeId,
                                 relationship: $0.relationship, strength: $0.strength) }
        }

        // 重新计算布局
        computeLayout()
    }

    // MARK: - 力导向布局（简化版 Fruchterman-Reingold）
    func computeLayout(in size: CGSize = CGSize(width: 600, height: 600)) {
        guard !filteredNodes.isEmpty else { nodePositions = [:]; return }

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let area = size.width * size.height
        let k = sqrt(area / Double(filteredNodes.count)) * 0.8
        let iterations = 60

        // 初始化随机位置
        var positions: [UUID: CGPoint] = [:]
        for node in filteredNodes {
            positions[node.id] = CGPoint(
                x: center.x + CGFloat.random(in: -100...100),
                y: center.y + CGFloat.random(in: -100...100)
            )
        }

        let edgeSet = Set(edges.map { (min($0.fromId, $0.toId), max($0.fromId, $0.toId)) })

        for iter in 0..<iterations {
            var displacements: [UUID: CGPoint] = [:]

            // 斥力（所有节点对）
            let nodeList = Array(filteredNodes)
            for i in 0..<nodeList.count {
                for j in (i + 1)..<nodeList.count {
                    let a = nodeList[i], b = nodeList[j]
                    let pa = positions[a.id]!, pb = positions[b.id]!
                    var delta = CGPoint(x: pa.x - pb.x, y: pa.y - pb.y)
                    let dist = max(sqrt(delta.x * delta.x + delta.y * delta.y), 1)
                    let force = k * k / dist
                    delta = CGPoint(x: delta.x / dist * force, y: delta.y / dist * force)

                    displacements[a.id, default: .zero] = CGPoint(
                        x: displacements[a.id]!.x + delta.x,
                        y: displacements[a.id]!.y + delta.y)
                    displacements[b.id, default: .zero] = CGPoint(
                        x: displacements[b.id]!.x - delta.x,
                        y: displacements[b.id]!.y - delta.y)
                }
            }

            // 引力（有边连接的节点对）
            for edge in edgeSet {
                let (aId, bId) = edge
                guard let pa = positions[aId], let pb = positions[bId] else { continue }
                var delta = CGPoint(x: pb.x - pa.x, y: pb.y - pa.y)
                let dist = sqrt(delta.x * delta.x + delta.y * delta.y)
                let force = dist * dist / k
                delta = CGPoint(x: delta.x / max(dist, 1) * force,
                                y: delta.y / max(dist, 1) * force)

                displacements[aId, default: .zero] = CGPoint(
                    x: displacements[aId]!.x + delta.x,
                    y: displacements[aId]!.y + delta.y)
                displacements[bId, default: .zero] = CGPoint(
                    x: displacements[bId]!.x - delta.x,
                    y: displacements[bId]!.y - delta.y)
            }

            // 应用位移（带冷却）
            let temp = 1.0 - Double(iter) / Double(iterations)
            for node in filteredNodes {
                let disp = displacements[node.id] ?? .zero
                let d = sqrt(disp.x * disp.x + disp.y * disp.y)
                let maxDisp = temp * k
                let scale = min(d, maxDisp) / max(d, 1)
                positions[node.id] = CGPoint(
                    x: positions[node.id]!.x + disp.x * scale,
                    y: positions[node.id]!.y + disp.y * scale)
            }
        }

        // 边界约束
        for node in filteredNodes {
            var p = positions[node.id]!
            p.x = max(30, min(size.width - 30, p.x))
            p.y = max(30, min(size.height - 30, p.y))
            positions[node.id] = p
        }

        nodePositions = positions
        layoutReady = true
    }

    // MARK: - 节点查找
    func findNode(at point: CGPoint) -> UUID? {
        for graphNode in filteredNodes {
            guard let pos = nodePositions[graphNode.id] else { continue }
            let dx = point.x - pos.x
            let dy = point.y - pos.y
            if sqrt(dx * dx + dy * dy) < graphNode.radius + 8 {
                return graphNode.id
            }
        }
        return nil
    }

    func selectNode(at id: UUID) {
        guard let node = nodes.first(where: { $0.id == id }) else { return }
        selectedNode = node
        showNodeDetail = true
    }

    // MARK: - 路径高亮
    func highlightPath(from sourceId: UUID, to targetId: UUID) {
        if let path = graphEngine.findShortestPath(from: sourceId, to: targetId) {
            highlightedPath = path
        }
    }

    func clearHighlight() {
        highlightedPath = []
    }

    // MARK: - 统计
    var totalNodes: Int { nodes.count }
    var totalEdges: Int { edges.count }
    var avgMastery: Double {
        guard !nodes.isEmpty else { return 0 }
        return nodes.map(\.masteryLevel).reduce(0, +) / Double(nodes.count)
    }
    var criticalCount: Int {
        nodes.filter { $0.forgettingCurve?.riskLevel == .critical }.count
    }

    var availableCategories: [KnowledgeCategory] {
        Array(Set(nodes.map(\.category))).sorted(by: <)
    }
}
