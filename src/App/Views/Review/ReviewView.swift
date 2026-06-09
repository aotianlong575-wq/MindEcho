import SwiftUI
import MindEchoCore

/// 鏅鸿兘澶嶄範
/// 姣忔棩鑷姩鐢熸垚澶嶄範璁″垝锛孉I 闅忔満鍑洪
struct ReviewView: View {
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: String?
    @State private var showResult = false
    @State private var isCorrect: Bool?

    var body: some View {
        NavigationStack {
            VStack {
                // 澶嶄範杩涘害
                ReviewProgressBar(current: currentQuestionIndex + 1, total: 10)

                // 棰樼洰鍗＄墖
                ScrollView {
                    VStack(spacing: 20) {
                        QuestionCard(
                            type: .multipleChoice,
                            question: "鑹惧娴╂柉閬楀繕鏇茬嚎琛ㄦ槑锛岄仐蹇樼殑杩涚▼鏄紵",
                            options: [
                                "A. 鍏堝揩鍚庢參",
                                "B. 鍏堟參鍚庡揩",
                                "C. 鍖€閫熼仐蹇?,
                                "D. 闅忔満閬楀繕"
                            ],
                            selectedAnswer: $selectedAnswer,
                            showResult: showResult,
                            correctAnswer: "A. 鍏堝揩鍚庢參"
                        )

                        if showResult {
                            HStack(spacing: 20) {
                                if isCorrect == true {
                                    Label("鍥炵瓟姝ｇ‘锛?, systemImage: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Label("鍥炵瓟閿欒", systemImage: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }

                                Button("涓嬩竴棰?) {
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
                            Button("鎻愪氦绛旀") {
                                withAnimation {
                                    showResult = true
                                    isCorrect = selectedAnswer == "A. 鍏堝揩鍚庢參"
                                }
                            }
                            .disabled(selectedAnswer == nil)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("鏅鸿兘澶嶄範")
        }
    }
}

// MARK: - 杩涘害鏉?struct ReviewProgressBar: View {
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

// MARK: - 棰樼洰鍗＄墖
struct QuestionCard: View {
    let type: QuestionType
    let question: String
    let options: [String]?
    let selectedAnswer: Binding<String?>
    let showResult: Bool
    let correctAnswer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 棰樺瀷鏍囩
            Label(type.rawValue, systemImage: typeIcon)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(.blue.opacity(0.1)))

            // 棰樼洰
            Text(question)
                .font(.body)
                .padding(.vertical, 8)

            // 閫夐」
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
