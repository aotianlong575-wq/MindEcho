import SwiftUI
import MindEchoCore

/// 智能复习 ViewModel
/// 管理复习会话、题目生成、答题评分、错题追踪
@MainActor
final class ReviewViewModel: ObservableObject {
    // MARK: - 复习状态
    @Published var currentPlan: ReviewPlan?
    @Published var currentItem: ReviewItem?
    @Published var currentIndex: Int = 0
    @Published var showResult = false
    @Published var isCorrect: Bool?
    @Published var selectedAnswer: String?

    // MARK: - 会话统计
    @Published var sessionCorrect = 0
    @Published var sessionWrong = 0
    @Published var sessionStartTime: Date?
    @Published var sessionElapsed: TimeInterval = 0
    @Published var isSessionActive = false

    // MARK: - 错题本
    @Published var wrongAnswers: [ReviewItem] = []
    @Published var showWrongBook = false

    // MARK: - 历史
    @Published var recentScores: [ReviewPlan] = []

    private let questionGen = QuestionGenerator()
    private let engine = ForgettingCurveEngine.self
    private var allNodes: [KnowledgeNode] = []
    private var timer: Timer?

    // MARK: - 生成复习计划
    func generatePlan(from nodes: [KnowledgeNode], maxItems: Int = 10) {
        allNodes = nodes
        currentPlan = engine.generateReviewPlan(for: nodes, maxItems: maxItems)
        currentIndex = 0
        sessionCorrect = 0; sessionWrong = 0
        selectedAnswer = nil; showResult = false; isCorrect = nil
        loadCurrentItem()
        startSession()
    }

    // MARK: - 加载当前题目
    func loadCurrentItem() {
        guard let plan = currentPlan, currentIndex < plan.items.count else {
            endSession()
            return
        }
        var item = plan.items[currentIndex]
        // 用实际节点内容生成更好的题目
        if let node = allNodes.first(where: { $0.id == item.nodeId }) {
            let qItem = questionGen.generateBestQuestion(for: node)
            item.question = qItem.question
            item.options = qItem.options
            item.correctAnswer = qItem.correctAnswer
        }
        currentItem = item
        currentPlan?.items[currentIndex] = item
    }

    // MARK: - 提交答案
    func submitAnswer() {
        guard let answer = selectedAnswer, let item = currentItem, var plan = currentPlan else { return }
        let correct = questionGen.checkAnswer(
            userAnswer: answer, correctAnswer: item.correctAnswer,
            type: item.questionType)
        isCorrect = correct; showResult = true

        plan.items[currentIndex].userAnswer = answer
        plan.items[currentIndex].isCorrect = correct

        if correct { sessionCorrect += 1 }
        else {
            sessionWrong += 1
            wrongAnswers.append(plan.items[currentIndex])
            // 更新 SM-2
            if var node = allNodes.first(where: { $0.id == item.nodeId }) {
                node.sm2Data = engine.sm2Update(sm2Data: node.sm2Data, quality: .completeBlackout)
                node.masteryLevel = engine.updateMastery(currentMastery: node.masteryLevel, quality: .completeBlackout)
                node.reviewHistory.append(.init(date: Date(), quality: .completeBlackout, durationSeconds: 0))
                if let idx = allNodes.firstIndex(where: { $0.id == item.nodeId }) {
                    allNodes[idx] = node
                }
            }
        }

        currentPlan = plan
    }

    func nextQuestion() {
        guard let plan = currentPlan else { return }
        if currentIndex + 1 < plan.items.count {
            currentIndex += 1
            selectedAnswer = nil; showResult = false; isCorrect = nil
            loadCurrentItem()
        } else {
            endSession()
        }
    }

    // MARK: - 会话管理
    func startSession() {
        isSessionActive = true
        sessionStartTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if let start = self?.sessionStartTime {
                    self?.sessionElapsed = Date().timeIntervalSince(start)
                }
            }
        }
    }

    func endSession() {
        isSessionActive = false
        timer?.invalidate(); timer = nil
        if var plan = currentPlan {
            plan.isCompleted = true
            let total = plan.items.count
            plan.score = total > 0 ? Double(sessionCorrect) / Double(total) * 100 : 0
            recentScores.insert(plan, at: 0)
            if recentScores.count > 20 { recentScores.removeLast() }
            currentPlan = plan
        }
    }

    // MARK: - 计算属性
    var totalQuestions: Int { currentPlan?.items.count ?? 0 }
    var progress: Double { totalQuestions > 0 ? Double(currentIndex + 1) / Double(totalQuestions) : 0 }
    var accuracy: Double {
        let total = sessionCorrect + sessionWrong
        return total > 0 ? Double(sessionCorrect) / Double(total) : 0
    }

    var formattedElapsed: String {
        let mins = Int(sessionElapsed) / 60
        let secs = Int(sessionElapsed) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - 历史统计
    var averageScore: Double {
        guard !recentScores.isEmpty else { return 0 }
        return recentScores.compactMap(\.score).reduce(0, +) / Double(recentScores.count)
    }
    var totalReviews: Int { recentScores.count }
}
