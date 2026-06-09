import SwiftUI
import MindEchoCore

/// 智能复习 — 每日计划 + 四种题型 + 错题本
struct ReviewView: View {
    @StateObject private var vm = ReviewViewModel()
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.isSessionActive {
                    activeReviewView
                } else {
                    preReviewView
                }
            }
            .navigationTitle("智能复习")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        if vm.isSessionActive {
                            Text(vm.formattedElapsed).font(.caption).foregroundColor(.secondary)
                        }
                        Button { vm.showWrongBook = true } label: {
                            Label("错题本", systemImage: "book")
                                .labelStyle(.titleAndIcon)
                                .font(.caption)
                        }
                        Button { showHistory = true } label: {
                            Image(systemName: "chart.bar.doc.horizontal")
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.showWrongBook) {
                WrongAnswerBookView(wrongAnswers: vm.wrongAnswers)
            }
            .sheet(isPresented: $showHistory) {
                ReviewHistoryView(recentScores: vm.recentScores)
            }
        }
    }

    // MARK: - 复习前
    private var preReviewView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 72))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple],
                    startPoint: .topLeading, endPoint: .bottomTrailing))

            VStack(spacing: 8) {
                Text("智能复习").font(.title.bold())
                Text("基于遗忘曲线动态生成每日复习计划")
                    .font(.caption).foregroundColor(.secondary)
            }

            // 上一次成绩
            if let last = vm.recentScores.first, let score = last.score {
                HStack {
                    Text("上次得分").foregroundColor(.secondary)
                    Text(String(format: "%.0f 分", score))
                        .font(.title3.bold())
                        .foregroundColor(score >= 80 ? .green : score >= 60 ? .orange : .red)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(spacing: 12) {
                Button {
                    let sampleNodes = makeSampleNodes()
                    vm.generatePlan(from: sampleNodes, maxItems: 10)
                } label: {
                    Label("开始今日复习", systemImage: "play.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity).frame(height: 48)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    let sampleNodes = makeSampleNodes()
                    vm.generatePlan(from: sampleNodes, maxItems: 5)
                } label: {
                    Label("快速复习 (5题)", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity).frame(height: 44)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - 复习中
    private var activeReviewView: some View {
        VStack(spacing: 0) {
            // 顶部进度
            HStack {
                Button("结束") { vm.endSession() }.font(.caption)
                Spacer()
                Text("\(vm.currentIndex + 1) / \(vm.totalQuestions)")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 8) {
                    Label("\(vm.sessionCorrect)", systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundColor(.green)
                    Label("\(vm.sessionWrong)", systemImage: "xmark.circle.fill")
                        .font(.caption).foregroundColor(.red)
                }
            }
            .padding(.horizontal).padding(.vertical, 6)
            .background(.ultraThinMaterial)

            ProgressView(value: vm.progress).tint(.blue)
                .padding(.horizontal)

            // 题目区
            ScrollView {
                if let item = vm.currentItem {
                    VStack(spacing: 16) {
                        QuestionCardView(
                            item: item,
                            selectedAnswer: $vm.selectedAnswer,
                            showResult: vm.showResult,
                            isCorrect: vm.isCorrect,
                            questionNumber: vm.currentIndex + 1
                        )
                        .padding()

                        if vm.showResult {
                            resultSection
                        } else {
                            Button("提交答案") { vm.submitAnswer() }
                                .disabled(vm.selectedAnswer == nil)
                                .buttonStyle(.borderedProminent)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 结果区域
    private var resultSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                if vm.isCorrect == true {
                    Label("回答正确！", systemImage: "checkmark.circle.fill")
                        .font(.headline).foregroundColor(.green)
                } else {
                    VStack(spacing: 4) {
                        Label("回答错误", systemImage: "xmark.circle.fill")
                            .font(.headline).foregroundColor(.red)
                        if let item = vm.currentItem {
                            Text("正确答案: \(item.correctAnswer)")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button("下一题") { vm.nextQuestion() }
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - 题目卡片
struct QuestionCardView: View {
    let item: ReviewItem
    @Binding var selectedAnswer: String?
    let showResult: Bool
    let isCorrect: Bool?
    let questionNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(item.questionType.rawValue, systemImage: typeIcon)
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(.blue.opacity(0.1)))
                Spacer()
                Text("第 \(questionNumber) 题")
                    .font(.caption).foregroundColor(.secondary)
            }

            Text(item.question).font(.body)

            if let options = item.options {
                ForEach(options, id: \.self) { opt in
                    Button { selectedAnswer = opt } label: {
                        HStack {
                            Text(opt).foregroundColor(.primary)
                            Spacer()
                            if selectedAnswer == opt {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10)
                            .stroke(optBorderColor(opt), lineWidth: optBorderWidth(opt)))
                    }
                    .disabled(showResult)
                }
            } else {
                // 填空题/问答题
                TextField("输入你的答案...", text: Binding(
                    get: { selectedAnswer ?? "" },
                    set: { selectedAnswer = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .disabled(showResult)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var typeIcon: String {
        switch item.questionType {
        case .multipleChoice: return "list.bullet"
        case .trueFalse: return "arrow.triangle.branch"
        case .fillInBlank: return "text.insert"
        case .shortAnswer: return "text.alignleft"
        }
    }

    private func optBorderColor(_ opt: String) -> Color {
        guard showResult else { return .secondary.opacity(0.3) }
        if opt == item.correctAnswer { return .green }
        if opt == selectedAnswer { return .red }
        return .secondary.opacity(0.3)
    }

    private func optBorderWidth(_ opt: String) -> CGFloat {
        (showResult && (opt == item.correctAnswer || opt == selectedAnswer)) ? 2 : 1
    }
}

// MARK: - 错题本
struct WrongAnswerBookView: View {
    let wrongAnswers: [ReviewItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if wrongAnswers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy.fill").font(.system(size: 48)).foregroundColor(.yellow)
                        Text("暂无错题 🎉").font(.headline)
                    }
                } else {
                    List(wrongAnswers.reversed()) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.question).font(.subheadline)
                            HStack {
                                Label("你的答案: \(item.userAnswer ?? "-")", systemImage: "xmark")
                                    .font(.caption).foregroundColor(.red)
                                Spacer()
                                Label("正确: \(item.correctAnswer)", systemImage: "checkmark")
                                    .font(.caption).foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("错题本 (\(wrongAnswers.count))")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 复习历史
struct ReviewHistoryView: View {
    let recentScores: [ReviewPlan]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if recentScores.isEmpty {
                    Text("暂无复习记录").foregroundColor(.secondary)
                } else {
                    List(recentScores) { plan in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(plan.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                Text("\(plan.completedCount)/\(plan.totalTarget) 题")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            if let score = plan.score {
                                Text(String(format: "%.0f%%", score))
                                    .font(.headline)
                                    .foregroundColor(score >= 80 ? .green : score >= 60 ? .orange : .red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("复习历史")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 示例节点
private func makeSampleNodes() -> [KnowledgeNode] {
    let data: [(String, String, [String], KnowledgeCategory, DifficultyLevel)] = [
        ("机器学习", "使计算机从数据中学习的方法", ["AI","ML"], .concept, .intermediate),
        ("监督学习", "使用标注数据训练模型", ["ML"], .procedure, .intermediate),
        ("神经网络", "模拟生物神经元的计算模型", ["DL"], .concept, .advanced),
        ("反向传播", "通过链式法则计算梯度", ["DL","优化"], .procedure, .advanced),
        ("过拟合", "模型在训练集表现好但泛化差", ["ML"], .concept, .intermediate),
        ("正则化", "防止过拟合的技术", ["ML"], .procedure, .advanced),
        ("梯度下降", "沿梯度方向优化参数", ["优化"], .procedure, .intermediate),
        ("损失函数", "衡量模型预测误差的函数", ["数学"], .concept, .elementary),
        ("特征工程", "从原始数据提取特征", ["数据"], .procedure, .intermediate),
        ("卷积神经网络", "用于图像处理", ["DL","CV"], .concept, .advanced),
    ]
    var nodes: [KnowledgeNode] = []
    for (t, c, tags, cat, diff) in data {
        nodes.append(KnowledgeNode(
            id: UUID(), title: t, content: c, tags: tags,
            category: cat, difficulty: diff, createdAt: Date(),
            lastReviewedAt: nil, reviewCount: 0, relatedNodes: [],
            forgettingCurve: nil, masteryLevel: Double.random(in: 0.3...0.8),
            sm2Data: .init(), reviewHistory: []))
    }
    let preds = ForgettingCurveEngine.predictForgetting(for: nodes)
    for i in nodes.indices { nodes[i].forgettingCurve = preds[nodes[i].id] }
    return nodes
}
