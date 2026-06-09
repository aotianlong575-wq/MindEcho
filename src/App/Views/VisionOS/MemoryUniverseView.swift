import SwiftUI
import MindEchoCore

#if os(visionOS)
import RealityKit

/// 记忆宇宙 — visionOS 核心创新模块
/// 知识点以三维星球形式展示，支持手势交互
struct MemoryUniverseView: View {
    @State private var nodes: [KnowledgeNode] = []
    @State private var selectedNode: KnowledgeNode?
    @State private var showNodeDetail = false
    @State private var showHeatmap = false

    var body: some View {
        RealityView { content in
            let root = Entity()
            root.name = "MemoryUniverseRoot"

            // 创建环境光
            let light = DirectionalLight()
            light.light?.intensity = 1000
            light.position = [0, 2, 2]
            root.addChild(light)

            content.add(root)

            // 为每个知识聚类创建星球（基于 Category）
            let clusters = Dictionary(grouping: nodes) { $0.category }
            let centerEntity = Entity()
            centerEntity.position = [0, 1.5, -2]
            root.addChild(centerEntity)

            // 创建轨道布局
            let clusterArray = Array(clusters)
            for (index, cluster) in clusterArray.enumerated() {
                let angle = Float(index) / Float(clusterArray.count) * .pi * 2
                let radius: Float = 1.2
                let planetPos = SIMD3<Float>(
                    cos(angle) * radius,
                    Float.random(in: -0.3...0.3),
                    sin(angle) * radius - 2
                )

                // 创建星球节点
                let planet = createPlanet(for: cluster.value, at: planetPos)
                centerEntity.addChild(planet)
            }
        } update: { content in
            // 数据更新时重建
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { _ in showNodeDetail = true }
        )
        .ornament(attachmentAnchor: .scene(.bottom)) {
            HStack(spacing: 24) {
                Button { /* 重置视角 */ } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                Button { /* 搜索 */ } label: {
                    Image(systemName: "magnifyingglass")
                }
                Button { showHeatmap.toggle() } label: {
                    Image(systemName: showHeatmap ? "flame.fill" : "flame")
                }
                Button { /* 全部展示 */ } label: {
                    Image(systemName: "sparkles")
                }
            }
            .padding()
            .glassBackgroundEffect()
        }
        .sheet(isPresented: $showNodeDetail) {
            if let node = selectedNode {
                VisionNodeDetail(node: node)
            }
        }
        .onAppear { nodes = makeSampleKnowledgeNodes() }
    }

    // MARK: - 创建星球
    private func createPlanet(for clusterNodes: [KnowledgeNode], at position: SIMD3<Float>) -> Entity {
        let planet = Entity()
        planet.position = position

        // 主球体
        let mesh = MeshResource.generateSphere(radius: 0.15)
        let material = SimpleMaterial(color: clusterColor(clusterNodes[0].category), isMetallic: false)
        let model = ModelComponent(mesh: mesh, materials: [material])
        planet.components.set(model)

        // 碰撞检测
        planet.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.2)]))

        // 名称标签
        let count = clusterNodes.count
        planet.name = "\(clusterNodes[0].category.rawValue) (\(count))"

        // 子节点（知识点小卫星）
        for (i, node) in clusterNodes.prefix(6).enumerated() {
            let moonAngle = Float(i) / Float(min(clusterNodes.count, 6)) * .pi * 2
            let moonRadius: Float = 0.25
            let moonPos = SIMD3<Float>(
                cos(moonAngle) * moonRadius,
                sin(moonAngle) * moonRadius,
                0
            )
            let moon = Entity()
            moon.position = moonPos
            let moonMesh = MeshResource.generateSphere(radius: 0.04)
            let moonMat = SimpleMaterial(color: masteryColor(node.masteryLevel), isMetallic: false)
            moon.components.set(ModelComponent(mesh: moonMesh, materials: [moonMat]))
            moon.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.06)]))
            moon.name = node.title
            planet.addChild(moon)
        }

        return planet
    }

    private func clusterColor(_ category: KnowledgeCategory) -> UIColor {
        switch category {
        case .concept: return .systemBlue
        case .principle: return .systemPurple
        case .procedure: return .systemGreen
        case .fact: return .systemOrange
        case .skill: return .systemTeal
        }
    }

    private func masteryColor(_ mastery: Double) -> UIColor {
        switch mastery {
        case 0..<0.3: return .systemRed
        case 0.3..<0.5: return .systemOrange
        case 0.5..<0.7: return .systemYellow
        case 0.7..<0.9: return .systemGreen
        default: return .systemTeal
        }
    }
}

struct VisionNodeDetail: View {
    let node: KnowledgeNode
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(node.title).font(.title)
            Text(node.content).foregroundColor(.secondary)
            Divider()
            LabeledContent("类别", value: node.category.rawValue)
            LabeledContent("难度", value: node.difficulty.rawValue)
            LabeledContent("掌握度", value: String(format: "%.0f%%", node.masteryLevel * 100))
            if !node.tags.isEmpty {
                Label("标签", systemImage: "tag.fill")
                HStack {
                    ForEach(node.tags, id: \.self) { tag in
                        Text(tag).font(.caption).padding(6)
                            .background(Capsule().fill(.ultraThinMaterial))
                    }
                }
            }
        }
        .padding(40).frame(width: 400, height: 500)
    }
}

#else
// 非 visionOS 平台的降级视图
struct MemoryUniverseView: View {
    @State private var nodes: [KnowledgeNode] = []
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "visionpro").font(.system(size: 60))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("记忆宇宙").font(.title.bold())
                Text("需要 Apple Vision Pro 体验沉浸式知识空间")
                    .foregroundColor(.secondary).multilineTextAlignment(.center)

                Divider().padding(.horizontal)

                // 平面降级展示：类别聚类
                Text("知识聚类预览").font(.headline)
                let categories = Dictionary(grouping: nodes) { $0.category }
                ForEach(Array(categories.keys), id: \.self) { cat in
                    let clusterNodes = categories[cat] ?? []
                    VStack(alignment: .leading, spacing: 6) {
                        Label("\(cat.rawValue) (\(clusterNodes.count))",
                              systemImage: "circle.hexagonpath.fill")
                            .font(.subheadline)
                        ForEach(clusterNodes.prefix(5)) { node in
                            HStack {
                                Circle()
                                    .fill(masteryColor(node.masteryLevel))
                                    .frame(width: 8, height: 8)
                                Text(node.title).font(.caption)
                                Spacer()
                                Text(String(format: "%.0f%%", node.masteryLevel * 100))
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .onAppear { nodes = makeSampleKnowledgeNodes() }
    }

    private func masteryColor(_ m: Double) -> Color {
        switch m {
        case ..<0.3: return .red
        case ..<0.5: return .orange
        case ..<0.7: return .yellow
        default: return .green
        }
    }
}
#endif

// MARK: - 示例节点（各模块共用）
func makeSampleKnowledgeNodes() -> [KnowledgeNode] {
    let data: [(String, String, [String], KnowledgeCategory, DifficultyLevel)] = [
        ("机器学习", "使计算机从数据中学习的方法", ["AI","ML"], .concept, .intermediate),
        ("监督学习", "使用标注数据训练模型", ["ML","监督"], .procedure, .intermediate),
        ("神经网络", "模拟生物神经元的计算模型", ["DL","网络"], .concept, .advanced),
        ("反向传播", "通过链式法则计算梯度", ["DL","优化"], .procedure, .advanced),
        ("过拟合", "模型在训练集表现好但泛化差", ["ML","问题"], .concept, .intermediate),
        ("正则化", "防止过拟合的技术", ["ML","优化"], .procedure, .advanced),
        ("梯度下降", "沿梯度方向优化参数", ["优化","数学"], .procedure, .intermediate),
        ("损失函数", "衡量模型预测误差的函数", ["数学","评估"], .concept, .elementary),
        ("特征工程", "从原始数据提取特征", ["数据","预处理"], .procedure, .intermediate),
        ("卷积神经网络", "用于图像处理", ["DL","CV"], .concept, .advanced),
    ]
    var nodes: [KnowledgeNode] = []
    for (t, c, tags, cat, diff) in data {
        nodes.append(KnowledgeNode(
            id: UUID(), title: t, content: c, tags: tags,
            category: cat, difficulty: diff,
            createdAt: Date().addingTimeInterval(-Double.random(in: 0...30) * 86400),
            lastReviewedAt: Date().addingTimeInterval(-Double.random(in: 0...3) * 86400),
            reviewCount: Int.random(in: 0...8), relatedNodes: [],
            forgettingCurve: nil, masteryLevel: Double.random(in: 0.2...0.95),
            sm2Data: .init(), reviewHistory: []))
    }
    let preds = ForgettingCurveEngine.predictForgetting(for: nodes)
    for i in nodes.indices { nodes[i].forgettingCurve = preds[nodes[i].id] }
    return nodes
}
