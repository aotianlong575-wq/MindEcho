import SwiftUI

/// 智能复习
/// 每日自动生成复习计划，AI 随机出题
struct ReviewView: View {
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: String?
    @State private var showResult = false
    @State private var isCorrect: Bool?

    var body: some View {
        NavigationStack {
            VStack {
                // 复习进度
                ReviewProgressBar(current: currentQuestionIndex + 1, total: 10)

                // 题目卡片
                ScrollView {
                    VStack(spacing: 20) {
                        QuestionCard(
                            type: .multipleChoice,
                            question: "艾宾浩斯遗忘曲线表明，遗忘的进程是？",
                            options: [
                                "A. 先快后慢",
                                "B. 先慢后快",
                                "C. 匀速遗忘",
                                "D. 随机遗忘"
                            ],
                            selectedAnswer: $selectedAnswer,
                            showResult: showResult,
                            correctAnswer: "A. 先快后慢"
                        )

                        if showResult {
                            HStack(spacing: 20) {
                                if isCorrect == true {
                                    Label("回答正确！", systemImage: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Label("回答错误", systemImage: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }

                                Button("下一题") {
                                    withAnimation {
                                        selectedAnswer = nil
                                        showResult = false
                                        currentQuestionIndex += 1
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            Button("提交答案") {
                                withAnimation {
                                    showResult = true
                                    isCorrect = selectedAnswer == "A. 先快后慢"
                                }
                            }
                            .disabled(selectedAnswer == nil)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("智能复习")
        }
    }
}

// MARK: - 进度条
struct ReviewProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(current), total: Double(total))
                .tint(.blue)
            Text("\(current) / \(total)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - 题目卡片
struct QuestionCard: View {
    let type: QuestionType
    let question: String
    let options: [String]?
    let selectedAnswer: Binding<String?>
    let showResult: Bool
    let correctAnswer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 题型标签
            Label(type.rawValue, systemImage: typeIcon)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(.blue.opacity(0.1)))

            // 题目
            Text(question)
                .font(.body)
                .padding(.vertical, 8)

            // 选项
            if let options = options {
                ForEach(options, id: \.self) { option in
                    Button {
                        selectedAnswer.wrappedValue = option
                    } label: {
                        HStack {
                            Text(option)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedAnswer.wrappedValue == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(optionBorderColor(option), lineWidth: optionBorderWidth(option))
                        )
                    }
                    .disabled(showResult)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var typeIcon: String {
        switch type {
        case .multipleChoice: return "list.bullet"
        case .trueFalse: return "arrow.triangle.branch"
        case .fillInBlank: return "text.insert"
        case .shortAnswer: return "text.alignleft"
        }
    }

    private func optionBorderColor(_ option: String) -> Color {
        guard showResult else { return .secondary.opacity(0.3) }
        if option == correctAnswer { return .green }
        if option == selectedAnswer.wrappedValue { return .red }
        return .secondary.opacity(0.3)
    }

    private func optionBorderWidth(_ option: String) -> CGFloat {
        (showResult && (option == correctAnswer || option == selectedAnswer.wrappedValue)) ? 2 : 1
    }
}
