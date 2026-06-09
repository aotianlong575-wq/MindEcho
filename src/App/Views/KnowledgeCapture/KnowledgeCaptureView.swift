import SwiftUI
import MindEchoCore
import PhotosUI
import MindEchoCore

/// 鐭ヨ瘑閲囬泦涓績
/// 鏀寔鎵嬪姩褰曞叆銆丱CR 璇嗗埆銆佹枃妗ｅ鍏ヤ笁绉嶆柟寮?struct KnowledgeCaptureView: View {
    @State private var selectedTab: CaptureTab = .manual
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack {
                Picker("閲囬泦鏂瑰紡", selection: $selectedTab) {
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
            .navigationTitle("鐭ヨ瘑閲囬泦")
        }
    }
}

enum CaptureTab: String, CaseIterable {
    case manual = "鎵嬪姩"
    case ocr = "OCR"
    case document = "鏂囨。"

    var icon: String {
        switch self {
        case .manual: return "pencil"
        case .ocr: return "camera.viewfinder"
        case .document: return "doc.fill"
        }
    }
}

// MARK: - 鎵嬪姩杈撳叆琛ㄥ崟
struct ManualInputForm: View {
    @State private var title = ""
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var category: KnowledgeCategory = .concept
    @State private var tagText = ""

    var body: some View {
        Form {
            Section("鍩烘湰淇℃伅") {
                TextField("鏍囬", text: $title)
                TextEditor(text: $content)
                    .frame(minHeight: 120)
            }

            Section("鍒嗙被") {
                Picker("绫诲埆", selection: $category) {
                    ForEach(KnowledgeCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
            }

            Section("鏍囩") {
                HStack {
                    TextField("娣诲姞鏍囩", text: $tagText)
                    Button("娣诲姞") {
                        if !tagText.isEmpty {
                            tags.append(tagText)
                            tagText = ""
                        }
                    }
                }
                TagCloudView(tags: $tags)
            }

            Button("淇濆瓨鐭ヨ瘑鐐?) {
                // TODO: 璋冪敤淇濆瓨閫昏緫
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - OCR 閲囬泦瑙嗗浘
struct OCRCaptureView: View {
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var recognizedText: String = ""

    var body: some View {
        VStack {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 48))
                    Text("閫夋嫨鍥剧墖杩涜 OCR 璇嗗埆")
                    Text("鏀寔鏁欐潗銆丳PT銆佹澘涔︺€佽瘯棰?)
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

// MARK: - 鏂囨。瀵煎叆瑙嗗浘
struct DocumentImportView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))

            Text("鎷栨斁鏂囦欢鎴栫偣鍑诲鍏?)
                .font(.headline)

            Text("鏀寔 PDF銆丏OCX銆乀XT銆丮arkdown 鏍煎紡")
                .font(.caption)
                .foregroundColor(.secondary)

            // TODO: 瀹炵幇鏂囦欢閫夋嫨鍣?        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - 鏍囩浜?struct TagCloudView: View {
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

/// 娴佸紡甯冨眬 (绠€鍖栧疄鐜?
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
