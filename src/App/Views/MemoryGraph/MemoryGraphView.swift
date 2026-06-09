import SwiftUI
import MindEchoCore

/// 璁板繂鍥捐氨 鈥?鐭ヨ瘑鑺傜偣涓庡叧绯荤殑鍙鍖?/// 鏀寔缂╂斁銆佹嫋鎷姐€佹悳绱€佺瓫閫?struct MemoryGraphView: View {
    @State private var searchText = ""
    @State private var selectedCategory: KnowledgeCategory?
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 鎼滅储鏍?                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("鎼滅储鐭ヨ瘑鐐?..", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)

                // 鍒嗙被绛涢€?                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "鍏ㄩ儴", isSelected: selectedCategory == nil) {
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

                // 鍥捐氨鐢诲竷
                ZStack {
                    // TODO: 浣跨敤 SpriteKit 鎴?Canvas 缁樺埗鐭ヨ瘑鍥捐氨
                    // 鑺傜偣琛ㄧず鐭ヨ瘑鐐癸紝杩炵嚎琛ㄧず鍏崇郴
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
            .navigationTitle("璁板繂鍥捐氨")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("鎸夋椂闂存帓搴?, action: {})
                        Button("鎸夐毦搴︽帓搴?, action: {})
                        Button("鏄剧ず鑱氱被", action: {})
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

// MARK: - 鍥捐氨鐢诲竷 (鍗犱綅)
struct GraphCanvasView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("鐭ヨ瘑鍥捐氨灏嗗湪姝ゅ睍绀?)
                .foregroundColor(.secondary)
            Text("娣诲姞鐭ヨ瘑鐐瑰悗锛岃妭鐐逛笌鍏宠仈鍏崇郴灏嗚嚜鍔ㄧ敓鎴?)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
