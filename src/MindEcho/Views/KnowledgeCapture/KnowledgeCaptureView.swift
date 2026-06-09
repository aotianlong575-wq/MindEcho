import SwiftUI
import PhotosUI

/// 知识采集中心
/// 支持手动录入、OCR 识别、文档导入三种方式
struct KnowledgeCaptureView: View {
    @State private var selectedTab: CaptureTab = .manual
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack {
                Picker("采集方式", selection: $selectedTab) {
                    ForEach(CaptureTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .manual:
                    ManualInputForm()
                case .ocr:
                    OCRCaptureView()
                case .document:
                    DocumentImportView()
                }
            }
            .navigationTitle("知识采集")
        }
    }
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

// MARK: - 手动输入表单
struct ManualInputForm: View {
    @State private var title = ""
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var category: KnowledgeCategory = .concept
    @State private var tagText = ""

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("标题", text: $title)
                TextEditor(text: $content)
                    .frame(minHeight: 120)
            }

            Section("分类") {
                Picker("类别", selection: $category) {
                    ForEach(KnowledgeCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
            }

            Section("标签") {
                HStack {
                    TextField("添加标签", text: $tagText)
                    Button("添加") {
                        if !tagText.isEmpty {
                            tags.append(tagText)
                            tagText = ""
                        }
                    }
                }
                TagCloudView(tags: $tags)
            }

            Button("保存知识点") {
                // TODO: 调用保存逻辑
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - OCR 采集视图
struct OCRCaptureView: View {
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var recognizedText: String = ""

    var body: some View {
        VStack {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 48))
                    Text("选择图片进行 OCR 识别")
                    Text("支持教材、PPT、板书、试题")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if !recognizedText.isEmpty {
                TextEditor(text: $recognizedText)
                    .frame(minHeight: 150)
                    .padding()
            }
        }
        .padding()
    }
}

// MARK: - 文档导入视图
struct DocumentImportView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))

            Text("拖放文件或点击导入")
                .font(.headline)

            Text("支持 PDF、DOCX、TXT、Markdown 格式")
                .font(.caption)
                .foregroundColor(.secondary)

            // TODO: 实现文件选择器
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - 标签云
struct TagCloudView: View {
    @Binding var tags: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags.indices, id: \.self) { index in
                HStack(spacing: 4) {
                    Text(tags[index])
                    Button {
                        tags.remove(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(.ultraThinMaterial))
            }
        }
    }
}

/// 流式布局 (简化实现)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal: proposal, subviews: subviews)
        let height = rows.last.flatMap { $0.map { $0.size.height }.max() ?? 0 } ?? 0
        let maxY = rows.count > 0 ? CGFloat(rows.count - 1) * (height + spacing) + height : 0
        return CGSize(width: proposal.width ?? 0, height: maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        var y = bounds.minY
        let height = rows.last?.first?.sizeThatFits(.unspecified).height ?? 0
        for row in rows {
            var x = bounds.minX
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += height + spacing
        }
    }

    func arrange(proposal: ProposedViewSize, subviews: Subviews) -> [[Subviews.Element]] {
        var rows: [[Subviews.Element]] = [[]]
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append(subview)
            x += size.width + spacing
        }
        return rows
    }
}
