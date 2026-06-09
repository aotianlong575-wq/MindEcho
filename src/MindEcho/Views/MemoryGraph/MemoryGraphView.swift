import SwiftUI

/// 记忆图谱 — 知识节点与关系的可视化
/// 支持缩放、拖拽、搜索、筛选
struct MemoryGraphView: View {
    @State private var searchText = ""
    @State private var selectedCategory: KnowledgeCategory?
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索知识点...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)

                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "全部", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(KnowledgeCategory.allCases, id: \.self) { cat in
                            FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                // 图谱画布
                ZStack {
                    // TODO: 使用 SpriteKit 或 Canvas 绘制知识图谱
                    // 节点表示知识点，连线表示关系
                    GraphCanvasView()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = max(0.3, min(3.0, value))
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = value.translation
                                    }
                            )
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("记忆图谱")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("按时间排序", action: {})
                        Button("按难度排序", action: {})
                        Button("显示聚类", action: {})
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.ultraThinMaterial))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - 图谱画布 (占位)
struct GraphCanvasView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("知识图谱将在此展示")
                .foregroundColor(.secondary)
            Text("添加知识点后，节点与关联关系将自动生成")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
