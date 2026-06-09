#if os(visionOS)
import SwiftUI
import RealityKit

/// 记忆宇宙 — visionOS 核心创新模块
/// 知识点以三维空间形式展示
/// 用户通过手势交互查看知识节点、路径、成长轨迹、记忆热力图
struct MemoryUniverseView: View {
    @State private var selectedNode: KnowledgeNode?
    @State private var showNodeDetail = false

    var body: some View {
        RealityView { content in
            // 创建根实体
            let root = Entity()
            root.name = "MemoryUniverseRoot"
            content.add(root)

            // TODO: 构建 3D 知识空间
            // 1. 创建星球节点（每个星球代表一个知识聚类）
            // 2. 创建连接线（表示知识关联路径）
            // 3. 添加粒子效果（记忆活跃度）
            // 4. 设置光照和材质
        } update: { content in
            // 响应数据更新
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    // 点击节点 -> 显示详情
                    showNodeDetail = true
                }
        )
        .ornament(attachmentAnchor: .scene(.bottom)) {
            // 底部控制栏
            HStack(spacing: 24) {
                Button(action: { /* 缩放重置 */ }) {
                    Image(systemName: "arrow.counterclockwise")
                }
                Button(action: { /* 搜索 */ }) {
                    Image(systemName: "magnifyingglass")
                }
                Button(action: { /* 筛选 */ }) {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                Button(action: { /* 热力图 */ }) {
                    Image(systemName: "flame.fill")
                }
            }
            .padding()
            .glassBackgroundEffect()
        }
        .sheet(isPresented: $showNodeDetail) {
            // 节点详情弹窗
            NodeDetailPanel(node: selectedNode)
        }
    }
}

// MARK: - 节点详情面板
struct NodeDetailPanel: View {
    let node: KnowledgeNode?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let node = node {
                Text(node.title)
                    .font(.title)
                Text(node.content)
                    .foregroundColor(.secondary)

                Divider()

                // 关联节点
                Label("关联知识", systemImage: "link")
                    .font(.headline)
                ForEach(node.relatedNodes.prefix(5), id: \.nodeId) { rel in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                        Text(rel.nodeId.uuidString.prefix(8))
                        Spacer()
                        Text(rel.relationship.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(40)
        .frame(width: 400, height: 500)
    }
}

#else
// 非 visionOS 平台的占位实现
import SwiftUI

struct MemoryUniverseView: View {
    var body: some View {
        VStack {
            Image(systemName: "visionpro")
                .font(.system(size: 60))
            Text("记忆宇宙")
                .font(.title)
            Text("需要 visionOS 设备")
                .foregroundColor(.secondary)
        }
    }
}
#endif
