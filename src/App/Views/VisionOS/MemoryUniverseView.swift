#if os(visionOS)
import SwiftUI
import MindEchoCore
import RealityKit
import MindEchoCore

/// 璁板繂瀹囧畽 鈥?visionOS 鏍稿績鍒涙柊妯″潡
/// 鐭ヨ瘑鐐逛互涓夌淮绌洪棿褰㈠紡灞曠ず
/// 鐢ㄦ埛閫氳繃鎵嬪娍浜や簰鏌ョ湅鐭ヨ瘑鑺傜偣銆佽矾寰勩€佹垚闀胯建杩广€佽蹇嗙儹鍔涘浘
struct MemoryUniverseView: View {
    @State private var selectedNode: KnowledgeNode?
    @State private var showNodeDetail = false

    var body: some View {
        RealityView { content in
            // 鍒涘缓鏍瑰疄浣?            let root = Entity()
            root.name = "MemoryUniverseRoot"
            content.add(root)

            // TODO: 鏋勫缓 3D 鐭ヨ瘑绌洪棿
            // 1. 鍒涘缓鏄熺悆鑺傜偣锛堟瘡涓槦鐞冧唬琛ㄤ竴涓煡璇嗚仛绫伙級
            // 2. 鍒涘缓杩炴帴绾匡紙琛ㄧず鐭ヨ瘑鍏宠仈璺緞锛?            // 3. 娣诲姞绮掑瓙鏁堟灉锛堣蹇嗘椿璺冨害锛?            // 4. 璁剧疆鍏夌収鍜屾潗璐?        } update: { content in
            // 鍝嶅簲鏁版嵁鏇存柊
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    // 鐐瑰嚮鑺傜偣 -> 鏄剧ず璇︽儏
                    showNodeDetail = true
                }
        )
        .ornament(attachmentAnchor: .scene(.bottom)) {
            // 搴曢儴鎺у埗鏍?            HStack(spacing: 24) {
                Button(action: { /* 缂╂斁閲嶇疆 */ }) {
                    Image(systemName: "arrow.counterclockwise")
                }
                Button(action: { /* 鎼滅储 */ }) {
                    Image(systemName: "magnifyingglass")
                }
                Button(action: { /* 绛涢€?*/ }) {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                Button(action: { /* 鐑姏鍥?*/ }) {
                    Image(systemName: "flame.fill")
                }
            }
            .padding()
            .glassBackgroundEffect()
        }
        .sheet(isPresented: $showNodeDetail) {
            // 鑺傜偣璇︽儏寮圭獥
            NodeDetailPanel(node: selectedNode)
        }
    }
}

// MARK: - 鑺傜偣璇︽儏闈㈡澘
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

                // 鍏宠仈鑺傜偣
                Label("鍏宠仈鐭ヨ瘑", systemImage: "link")
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
// 闈?visionOS 骞冲彴鐨勫崰浣嶅疄鐜?import SwiftUI
import MindEchoCore

struct MemoryUniverseView: View {
    var body: some View {
        VStack {
            Image(systemName: "visionpro")
                .font(.system(size: 60))
            Text("璁板繂瀹囧畽")
                .font(.title)
            Text("闇€瑕?visionOS 璁惧")
                .foregroundColor(.secondary)
        }
    }
}
#endif
