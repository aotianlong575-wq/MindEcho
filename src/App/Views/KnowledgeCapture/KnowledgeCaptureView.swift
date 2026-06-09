import SwiftUI
import PhotosUI
import MindEchoCore

/// 知识采集中心
/// 支持手动录入、OCR 识别、文档导入三种方式
struct KnowledgeCaptureView: View {
    @StateObject private var vm = KnowledgeCaptureViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 标签切换
                Picker("采集方式", selection: $vm.selectedTab) {
                    ForEach(KnowledgeCaptureViewModel.CaptureTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // 提示消息
                messagesBanner

                // 内容区域
                switch vm.selectedTab {
                case .manual: ManualInputForm(vm: vm)
                case .ocr:    OCRCaptureContent(vm: vm)
                case .document: DocumentImportContent(vm: vm)
                }
            }
            .navigationTitle("知识采集")
            .navigationDestination(isPresented: $vm.showParseResult) {
                ParseResultView(vm: vm)
            }
        }
    }

    // MARK: - 消息横幅
    private var messagesBanner: some View {
        Group {
            if let err = vm.errorMessage {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundColor(.red)
                    .padding(.horizontal).padding(.bottom, 4)
            } else if let msg = vm.successMessage {
                Label(msg, systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundColor(.green)
                    .padding(.horizontal).padding(.bottom, 4)
            }
        }
    }
}

// MARK: - 手动录入
struct ManualInputForm: View {
    @ObservedObject var vm: KnowledgeCaptureViewModel

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("标题", text: $vm.manualTitle)
                TextEditor(text: $vm.manualContent)
                    .frame(minHeight: 120)
            }

            Section("分类") {
                Picker("类别", selection: $vm.manualCategory) {
                    ForEach(KnowledgeCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
            }

            Section("标签") {
                HStack {
                    TextField("添加标签", text: $vm.manualTagText)
                        .onSubmit { vm.addTag() }
                    Button("添加") { vm.addTag() }
                        .buttonStyle(.bordered).controlSize(.small)
                }
                TagCloudView(tags: $vm.manualTags, onRemove: { vm.removeTag($0) })
            }

            Section {
                Button {
                    Task { await vm.saveManualEntry() }
                } label: {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Text("保存并解析").fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .disabled(vm.manualTitle.isEmpty || vm.manualContent.isEmpty || vm.isLoading)
            }
        }
    }
}

// MARK: - OCR 采集
struct OCRCaptureContent: View {
    @ObservedObject var vm: KnowledgeCaptureViewModel

    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $vm.selectedPhotoItem, matching: .images) {
                VStack(spacing: 12) {
                    Image(systemName: $vm.selectedPhotoItem.wrappedValue != nil
                          ? "doc.text.viewfinder.fill" : "doc.text.viewfinder")
                        .font(.system(size: 48))
                        .foregroundColor($vm.selectedPhotoItem.wrappedValue != nil ? .blue : .secondary)
                    Text($vm.selectedPhotoItem.wrappedValue != nil
                         ? "已选择图片，点击更换" : "选择图片进行 OCR 识别")
                    Text("支持教材、PPT、板书、试题")
                        .font(.caption).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 160)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Button {
                Task { await vm.runOCR() }
            } label: {
                if vm.isLoading {
                    ProgressView()
                } else {
                    Label("开始识别", systemImage: "text.viewfinder")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.selectedPhotoItem == nil || vm.isLoading)

            // 识别结果
            if !vm.ocrResultText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("识别结果")
                        .font(.headline).padding(.horizontal)
                    TextEditor(text: $vm.ocrResultText)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                }
            }

            // 知识候选项
            if !vm.ocrCandidates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("知识点候选 (\(vm.ocrCandidates.count))")
                            .font(.headline)
                        Spacer()
                        Button("全部导入") { vm.importAllOCRCandidates() }
                            .buttonStyle(.bordered).controlSize(.small)
                    }
                    .padding(.horizontal)

                    ForEach(vm.ocrCandidates, id: \.title) { candidate in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(candidate.title).font(.subheadline).fontWeight(.medium)
                                Text("\(candidate.category.rawValue) · \(candidate.difficulty.rawValue)")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("导入") { vm.importOCRCandidate(candidate) }
                                .buttonStyle(.bordered).controlSize(.small)
                                .tint(.green)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                    }
                }
            }

            Spacer()
        }
        .padding(.top)
    }
}

// MARK: - 文档导入
struct DocumentImportContent: View {
    @ObservedObject var vm: KnowledgeCaptureViewModel

    var body: some View {
        VStack(spacing: 16) {
            // 文件选择区域
            VStack(spacing: 12) {
                Image(systemName: vm.selectedFileURL != nil
                      ? "doc.badge.gearshape.fill" : "doc.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(vm.selectedFileURL != nil ? .blue : .secondary)

                if let url = vm.selectedFileURL {
                    VStack(spacing: 4) {
                        Text(vm.documentFileName)
                            .font(.headline)
                        Text("\(vm.documentText.count) 字符")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } else {
                    Text("选择文件导入").font(.headline)
                    Text("支持 PDF、TXT、Markdown 格式")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            // 文件选择按钮
            HStack(spacing: 12) {
                DocumentPickerButton(vm: vm)
                Button {
                    Task { await vm.parseDocument() }
                } label: {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Label("AI 解析文档", systemImage: "brain")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.documentText.isEmpty || vm.isLoading)
            }
            .padding(.horizontal)

            // 预览
            if !vm.documentText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("文档预览")
                        .font(.headline).padding(.horizontal)
                    ScrollView {
                        Text(vm.documentText)
                            .font(.caption).textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .padding(.top)
    }
}

// MARK: - 文档选择器按钮
struct DocumentPickerButton: View {
    @ObservedObject var vm: KnowledgeCaptureViewModel

    var body: some View {
        #if os(iOS)
        // iOS: 使用 UIDocumentPickerViewController wrapper
        Button {
            // 简化：手动输入文件路径进行测试
            showMockFilePicker()
        } label: {
            Label("浏览文件", systemImage: "folder")
        }
        .buttonStyle(.bordered)
        #else
        // macOS: 使用 fileImporter
        Button {
            showMockFilePicker()
        } label: {
            Label("浏览文件", systemImage: "folder")
        }
        .buttonStyle(.bordered)
        #endif
    }

    private func showMockFilePicker() {
        // 由于 UIDocumentPicker 需要 UIKit 集成，此处提供测试入口
        // 真实环境使用 NSOpenPanel (macOS) 或 UIDocumentPicker (iOS)
        let sampleContent = """
        # 机器学习基础

        机器学习是人工智能的一个分支，它使用算法从数据中学习模式。

        ## 监督学习
        监督学习需要标注数据。算法从输入-输出对中学习映射关系。

        ## 无监督学习
        无监督学习不需要标注数据。算法自动发现数据中的隐藏结构。

        ## 深度学习
        深度学习使用多层神经网络进行模式识别和特征提取。
        """
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("sample_knowledge.md")
        try? sampleContent.write(to: tempFile, atomically: true, encoding: .utf8)
        vm.loadDocument(url: tempFile)
    }
}

// MARK: - AI 解析结果视图
struct ParseResultView: View {
    @ObservedObject var vm: KnowledgeCaptureViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 节点列表
                Text("解析出的知识点 (\(vm.parsedNodes.count))")
                    .font(.title3.bold())
                    .padding(.horizontal)

                ForEach(vm.parsedNodes) { node in
                    NodeCard(node: node, relations: vm.parsedRelations)
                }

                // 关联关系
                if !vm.parsedRelations.isEmpty {
                    Text("发现的关联 (\(vm.parsedRelations.count))")
                        .font(.title3.bold())
                        .padding(.horizontal)

                    ForEach(vm.parsedRelations, id: \.sourceId) { rel in
                        HStack {
                            Image(systemName: "arrow.triangle.pull")
                                .foregroundColor(.blue)
                            Text("\(findNodeTitle(rel.sourceId))")
                            Image(systemName: "arrow.right").font(.caption)
                            Text("\(findNodeTitle(rel.targetId))")
                            Spacer()
                            Text(rel.type.rawValue)
                                .font(.caption)
                                .padding(4).padding(.horizontal, 6)
                                .background(Capsule().fill(.blue.opacity(0.1)))
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("解析结果")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("导入全部 (\(vm.parsedNodes.count))") {
                    vm.importAllParsedNodes()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.parsedNodes.isEmpty)
            }
        }
    }

    private func findNodeTitle(_ id: UUID) -> String {
        vm.parsedNodes.first(where: { $0.id == id })?.title ?? id.uuidString.prefix(8).description
    }
}

// MARK: - 知识节点卡片
struct NodeCard: View {
    let node: KnowledgeNode
    let relations: [AIKnowledgeParser.Relation]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(node.title).font(.headline)
                Spacer()
                CategoryBadge(category: node.category)
                DifficultyBadge(level: node.difficulty)
            }

            Text(node.content)
                .font(.caption).foregroundColor(.secondary)
                .lineLimit(3)

            // 标签
            if !node.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(node.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(Capsule().fill(.blue.opacity(0.1)))
                        }
                    }
                }
            }

            // 关联数
            let relatedCount = relations.filter { $0.sourceId == node.id || $0.targetId == node.id }.count
            if relatedCount > 0 {
                Label("\(relatedCount) 个关联", systemImage: "link")
                    .font(.caption2).foregroundColor(.blue)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - 辅助徽章
struct CategoryBadge: View {
    let category: KnowledgeCategory
    var body: some View {
        Text(category.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(.purple.opacity(0.15)))
            .foregroundColor(.purple)
    }
}

struct DifficultyBadge: View {
    let level: DifficultyLevel
    var body: some View {
        Text(level.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.15)))
            .foregroundColor(color)
    }
    var color: Color {
        switch level {
        case .beginner: return .green
        case .elementary: return .blue
        case .intermediate: return .orange
        case .advanced: return .red
        case .expert: return .purple
        }
    }
}

// MARK: - 标签云
struct TagCloudView: View {
    @Binding var tags: [String]
    var onRemove: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                HStack(spacing: 3) {
                    Text(tag).font(.caption)
                    Button { onRemove(tag) } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(.ultraThinMaterial))
            }
        }
        .padding(.vertical, 4)
    }
}
