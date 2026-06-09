import SwiftUI
import MindEchoCore

/// 记忆图谱 — 力导向布局可视化 + 搜索筛选 + 手势交互
struct MemoryGraphView: View {
    @StateObject private var vm = MemoryGraphViewModel()
    @State private var canvasSize: CGSize = .zero
    @State private var showPathSearch = false
    @State private var pathSourceTitle = ""
    @State private var pathTargetTitle = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                filterBar
                statsBar
                graphCanvas
            }
            .navigationTitle("记忆图谱")
            .toolbar { toolbarMenu }
            .sheet(isPresented: $vm.showNodeDetail) {
                if let node = vm.selectedNode {
                    NodeDetailView(node: node, allNodes: vm.nodes,
                                   onDismiss: { vm.showNodeDetail = false })
                }
            }
            .alert("路径搜索", isPresented: $showPathSearch) {
                TextField("起始节点关键词", text: $pathSourceTitle)
                TextField("目标节点关键词", text: $pathTargetTitle)
                Button("搜索") { searchPath() }
                Button("取消", role: .cancel) { vm.clearHighlight() }
            }
            .onAppear { if vm.nodes.isEmpty { loadSampleData() } }
        }
    }

    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("搜索知识点...", text: $vm.searchText)
                .textFieldStyle(.plain)
                .onSubmit { vm.applyFilters() }
            if !vm.searchText.isEmpty {
                Button { vm.searchText = ""; vm.applyFilters() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(10).background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding([.horizontal, .top])
    }

    // MARK: - 筛选栏
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(title: "全部", isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil; vm.applyFilters()
                }
                ForEach(vm.availableCategories, id: \.self) { cat in
                    FilterChip(title: cat.rawValue, isSelected: vm.selectedCategory == cat) {
                        vm.selectedCategory = (vm.selectedCategory == cat) ? nil : cat
                        vm.applyFilters()
                    }
                }
                Divider().frame(height: 20)
                ForEach(DifficultyLevel.allCases, id: \.self) { diff in
                    FilterChip(title: diff.rawValue, isSelected: vm.selectedDifficulty == diff) {
                        vm.selectedDifficulty = (vm.selectedDifficulty == diff) ? nil : diff
                        vm.applyFilters()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 6)
    }

    // MARK: - 统计栏
    private var statsBar: some View {
        HStack(spacing: 16) {
            StatBadge(label: "节点", value: "\(vm.filteredNodes.count)")
            StatBadge(label: "关联", value: "\(vm.edges.count)")
            StatBadge(label: "掌握度", value: String(format: "%.0f%%", vm.avgMastery * 100))
            if vm.criticalCount > 0 {
                HStack(spacing: 2) {
                    Text("高危").foregroundColor(.secondary)
                    Text("\(vm.criticalCount)").fontWeight(.semibold).foregroundColor(.red)
                }.font(.caption)
            }
        }
        .font(.caption).padding(.vertical, 4)
    }

    // MARK: - 图谱画布
    private var graphCanvas: some View {
        GeometryReader { geo in
            ZStack {
                if vm.filteredNodes.isEmpty {
                    emptyState
                } else {
                    Canvas { ctx, _ in
                        DispatchQueue.main.async {
                            if canvasSize != geo.size {
                                canvasSize = geo.size
                                vm.computeLayout(in: geo.size)
                            }
                        }
                        // 绘制边
                        for edge in vm.edges {
                            guard let fp = vm.nodePositions[edge.fromId],
                                  let tp = vm.nodePositions[edge.toId] else { continue }
                            let hl = vm.highlightedPath.contains(edge.fromId)
                                  && vm.highlightedPath.contains(edge.toId)
                            var path = Path(); path.move(to: fp); path.addLine(to: tp)
                            ctx.stroke(path, with: .color(hl ? .orange : .secondary.opacity(0.25)),
                                       lineWidth: hl ? 2.5 : max(edge.strength * 1.5, 0.5))
                        }
                        // 绘制节点
                        for g in vm.filteredNodes {
                            guard let pos = vm.nodePositions[g.id] else { continue }
                            let hl = vm.highlightedPath.contains(g.id)
                            let r = g.radius
                            let rect = CGRect(x: pos.x - r, y: pos.y - r, width: r * 2, height: r * 2)
                            let circle = Path(ellipseIn: rect)
                            ctx.fill(circle, with: .color(nodeColor(g, highlight: hl)))
                            if hl { ctx.stroke(circle, with: .color(.orange), lineWidth: 3) }
                            // 标签
                            let lbl = ctx.resolve(Text(g.title)
                                .font(.system(size: max(r * 0.45, 8))).foregroundColor(.primary))
                            ctx.draw(lbl, at: CGPoint(x: pos.x, y: pos.y + r + 10))
                        }
                    }
                    .scaleEffect(vm.scale).offset(vm.offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture().onChanged { vm.scale = max(0.3, min(3, $0)) },
                            DragGesture().onChanged { vm.offset = $0.translation }
                        )
                    )
                    .gesture(
                        SpatialTapGesture().onEnded { value in
                            // 反向计算缩放和偏移后的点击位置
                            let x = (value.location.x - vm.offset.width) / vm.scale
                            let y = (value.location.y - vm.offset.height) / vm.scale
                            if let id = vm.findNode(at: CGPoint(x: x, y: y)) {
                                vm.selectNode(at: id)
                            }
                        }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 60)).foregroundColor(.secondary)
            Text("知识图谱为空").font(.headline)
            Text("去「采集」页面添加知识点后，图谱将在此展示")
                .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
    }

    private var toolbarMenu: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                ForEach(SearchQuery.SortOption.allCases, id: \.self) { opt in
                    Button { vm.sortOption = opt; vm.applyFilters() } label: {
                        HStack {
                            Text(opt.rawValue)
                            if vm.sortOption == opt { Image(systemName: "checkmark") }
                        }
                    }
                }
                Divider()
                Button { showPathSearch = true } label: {
                    Label("路径搜索", systemImage: "arrow.triangle.turn.up.right.diamond")
                }
                Button { vm.computeLayout(in: canvasSize) } label: {
                    Label("重新布局", systemImage: "arrow.triangle.2.circlepath")
                }
            } label: { Image(systemName: "ellipsis.circle") }
        }
    }

    private func nodeColor(_ n: MemoryGraphViewModel.GraphNode, highlight: Bool) -> Color {
        if highlight { return .orange }
        switch n.riskLevel {
        case .critical: return .red.opacity(0.8)
        case .warning: return .orange.opacity(0.7)
        case .moderate: return .blue.opacity(0.6 + n.mastery * 0.3)
        case .good: return .green.opacity(0.6 + n.mastery * 0.2)
        case .excellent: return .teal.opacity(0.7)
        }
    }

    private func searchPath() {
        vm.clearHighlight()
        guard !pathSourceTitle.isEmpty, !pathTargetTitle.isEmpty else { return }
        let srcs = vm.nodes.filter { $0.title.contains(pathSourceTitle) }
        let tgts = vm.nodes.filter { $0.title.contains(pathTargetTitle) }
        guard let s = srcs.first, let t = tgts.first else { return }
        vm.highlightPath(from: s.id, to: t.id)
    }

    private func loadSampleData() {
        let data: [(String, String, [String], KnowledgeCategory, DifficultyLevel)] = [
            ("机器学习", "使计算机从数据中学习的方法", ["AI","ML"], .concept, .intermediate),
            ("监督学习", "使用标注数据训练模型", ["ML","监督"], .procedure, .intermediate),
            ("神经网络", "模拟生物神经元的计算模型", ["DL","网络"], .concept, .advanced),
            ("反向传播", "通过链式法则计算梯度", ["DL","优化"], .procedure, .advanced),
            ("过拟合", "模型在训练集表现好但泛化差", ["ML","问题"], .concept, .intermediate),
            ("正则化", "防止过拟合的技术", ["ML","优化"], .procedure, .advanced),
            ("梯度下降", "沿梯度方向优化参数", ["优化","数学"], .procedure, .intermediate),
            ("损失函数", "衡量模型预测误差的函数", ["数学","评估"], .concept, .elementary),
            ("特征工程", "从原始数据提取特征的过程", ["数据","预处理"], .procedure, .intermediate),
            ("卷积神经网络", "用于图像处理的深度网络", ["DL","CV"], .concept, .advanced),
        ]
        var nodes: [KnowledgeNode] = []
        for (t, c, tags, cat, diff) in data {
            nodes.append(KnowledgeNode(
                id: UUID(), title: t, content: c, tags: tags,
                category: cat, difficulty: diff,
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...30) * 86400),
                lastReviewedAt: nil, reviewCount: Int.random(in: 0...5),
                relatedNodes: [], forgettingCurve: nil,
                masteryLevel: Double.random(in: 0.2...0.95),
                sm2Data: .init(), reviewHistory: []))
        }
        let rels: [(Int, Int, RelationshipType)] = [
            (0,1,.prerequisite),(0,2,.extension_),(1,7,.related),
            (2,3,.prerequisite),(2,9,.extension_),(3,6,.related),
            (4,5,.application),(6,3,.related),(7,6,.related),
            (1,4,.related),(0,8,.related),(8,1,.prerequisite),
        ]
        for (i, j, type) in rels {
            nodes[i].relatedNodes.append(.init(nodeId: nodes[j].id, relationship: type, strength: 0.7))
            nodes[j].relatedNodes.append(.init(nodeId: nodes[i].id, relationship: type, strength: 0.7))
        }
        let preds = ForgettingCurveEngine.predictForgetting(for: nodes)
        for i in nodes.indices { nodes[i].forgettingCurve = preds[nodes[i].id] }
        vm.load(nodes: nodes)
    }
}

// MARK: - 节点详情
struct NodeDetailView: View {
    let node: KnowledgeNode
    let allNodes: [KnowledgeNode]
    var onDismiss: () -> Void
    @State private var connected: [KnowledgeNode] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        CategoryBadge(category: node.category)
                        DifficultyBadge(level: node.difficulty)
                        if let r = node.forgettingCurve?.riskLevel {
                            RiskBadge(level: r)
                        }
                    }
                    Text(node.title).font(.title.bold())
                    Text(node.content).foregroundColor(.secondary)

                    // 掌握度条
                    VStack(alignment: .leading, spacing: 4) {
                        Label("掌握度", systemImage: "chart.bar.fill").font(.headline)
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(.secondary.opacity(0.2)).frame(height: 12)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(node.masteryLevel > 0.7 ? AnyShapeStyle(.green) :
                                            node.masteryLevel > 0.4 ? AnyShapeStyle(.orange) : AnyShapeStyle(.red))
                                    .frame(width: g.size.width * node.masteryLevel, height: 12)
                            }
                        }.frame(height: 12)
                    }

                    if let c = node.forgettingCurve {
                        LabeledContent("保留率", value: String(format: "%.0f%%", c.retentionRate * 100))
                        LabeledContent("最佳复习", value: c.optimalReviewTime.formatted(date: .abbreviated, time: .shortened))
                    }

                    if !node.tags.isEmpty {
                        Label("标签", systemImage: "tag.fill").font(.headline)
                        TagCloudView(tags: .constant(node.tags), onRemove: { _ in })
                    }

                    if !connected.isEmpty {
                        Label("关联知识 (\(connected.count))", systemImage: "link").font(.headline)
                        ForEach(connected) { cn in
                            let rel = node.relatedNodes.first { $0.nodeId == cn.id }
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(cn.title).font(.subheadline).fontWeight(.medium)
                                    Text(cn.category.rawValue).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if let r = rel {
                                    Text(r.relationship.rawValue).font(.caption2)
                                        .padding(4).padding(.horizontal, 4)
                                        .background(Capsule().fill(.blue.opacity(0.1)))
                                }
                            }.padding(.vertical, 2)
                            Divider()
                        }
                    }
                }.padding()
            }
            .navigationTitle("节点详情").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { onDismiss() } } }
        }
        .onAppear { connected = node.relatedNodes.compactMap { rel in allNodes.first { $0.id == rel.nodeId } } }
    }
}

struct StatBadge: View {
    let label: String; let value: String
    var body: some View {
        HStack(spacing: 2) { Text(label).foregroundColor(.secondary); Text(value).fontWeight(.semibold) }
    }
}

struct RiskBadge: View {
    let level: ForgettingCurve.RiskLevel
    var body: some View {
        Text(level.rawValue).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.15))).foregroundColor(color)
    }
    var color: Color {
        switch level {
        case .critical: .red; case .warning: .orange
        case .moderate: .yellow; case .good: .green; case .excellent: .teal
        }
    }
}

struct FilterChip: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.caption).padding(.horizontal, 10).padding(.vertical, 5)
                .background(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.ultraThinMaterial))
                .foregroundColor(isSelected ? .white : .primary).clipShape(Capsule())
        }
    }
}
