import Foundation

/// AI 出题引擎
/// 根据知识点内容自动生成四种题型的题目
public final class QuestionGenerator {

    public init() {}

    // MARK: - 题目生成
    /// 为知识点生成题目
    /// - Parameters:
    ///   - node: 知识点
    ///   - type: 题目类型
    /// - Returns: ReviewItem
    public func generateQuestion(for node: KnowledgeNode, type: QuestionType) -> ReviewItem {
        switch type {
        case .multipleChoice:
            return generateMultipleChoice(for: node)
        case .trueFalse:
            return generateTrueFalse(for: node)
        case .fillInBlank:
            return generateFillInBlank(for: node)
        case .shortAnswer:
            return generateShortAnswer(for: node)
        }
    }

    /// 混合出题：根据节点特征选择最佳题型
    public func generateBestQuestion(for node: KnowledgeNode) -> ReviewItem {
        let type = bestQuestionType(for: node)
        return generateQuestion(for: node, type: type)
    }

    /// 为多个知识点批量出题
    public func generateQuestions(for nodes: [KnowledgeNode]) -> [ReviewItem] {
        nodes.map { generateBestQuestion(for: $0) }
    }

    // MARK: - 题型选择
    public func bestQuestionType(for node: KnowledgeNode) -> QuestionType {
        switch node.category {
        case .fact: return .trueFalse
        case .concept: return .multipleChoice
        case .procedure: return .fillInBlank
        case .principle: return .shortAnswer
        case .skill: return .multipleChoice
        }
    }

    // MARK: - 选择题
    private func generateMultipleChoice(for node: KnowledgeNode) -> ReviewItem {
        let keyTerms = extractKeyTerms(node.content)
        let correctTerm = keyTerms.first ?? node.title

        let distractors = generateDistractors(correctAnswer: correctTerm, from: keyTerms)
        var options = [correctTerm] + distractors
        options.shuffle()

        let correctIndex = options.firstIndex(of: correctTerm) ?? 0
        let labels = ["A", "B", "C", "D"]

        return ReviewItem(
            id: UUID(),
            nodeId: node.id,
            questionType: .multipleChoice,
            question: "以下哪一项与「\(node.title)」直接相关？",
            options: options.enumerated().map { "\(labels[$0.offset]). \($0.element)" },
            correctAnswer: labels[correctIndex]
        )
    }

    /// 生成干扰项
    private func generateDistractors(correctAnswer: String, from terms: [String]) -> [String] {
        let others = terms.filter { $0 != correctAnswer }
        var distractors: [String] = []

        // 取同义词特征的其他术语
        distractors.append(contentsOf: others.suffix(2))

        // 如果不够 3 个，生成变体
        while distractors.count < 3 {
            let variant = correctAnswer + ["理论", "方法", "模型", "原理", "技术"].randomElement()!
            if !distractors.contains(variant) {
                distractors.append(variant)
            }
        }
        return Array(distractors.prefix(3))
    }

    // MARK: - 判断题
    private func generateTrueFalse(for node: KnowledgeNode) -> ReviewItem {
        // 随机决定正确答案是真还是假
        let answerIsTrue = Bool.random()

        let question: String
        if answerIsTrue {
            question = "「\(node.title)」属于\(node.category.rawValue)类型知识。"
        } else {
            // 生成一个假的描述
            let wrongCategories = KnowledgeCategory.allCases.filter { $0 != node.category }
            let wrongCat = wrongCategories.randomElement() ?? .fact
            question = "「\(node.title)」属于\(wrongCat.rawValue)类型知识。"
        }

        return ReviewItem(
            id: UUID(),
            nodeId: node.id,
            questionType: .trueFalse,
            question: question,
            options: ["True", "False"],
            correctAnswer: answerIsTrue ? "True" : "False"
        )
    }

    // MARK: - 填空题
    private func generateFillInBlank(for node: KnowledgeNode) -> ReviewItem {
        let terms = extractKeyTerms(node.content)
        guard let blank = terms.first else {
            // 退化为问答题
            return generateShortAnswer(for: node)
        }

        let maskedContent = node.content.replacingOccurrences(of: blank, with: "______")

        return ReviewItem(
            id: UUID(),
            nodeId: node.id,
            questionType: .fillInBlank,
            question: "请在横线处填入正确的术语：\n\(maskedContent)",
            options: nil,
            correctAnswer: blank
        )
    }

    // MARK: - 问答题
    private func generateShortAnswer(for node: KnowledgeNode) -> ReviewItem {
        let prompts: [String] = [
            "请简述「\(node.title)」的含义。",
            "「\(node.title)」的核心要点是什么？",
            "请用自己的话解释「\(node.title)」。",
            "\(node.title)在实际中如何应用？",
            "请总结「\(node.title)」的关键特征。"
        ]

        return ReviewItem(
            id: UUID(),
            nodeId: node.id,
            questionType: .shortAnswer,
            question: prompts.randomElement()!,
            options: nil,
            correctAnswer: node.content
        )
    }

    // MARK: - 关键词提取
    private func extractKeyTerms(_ text: String) -> [String] {
        // 简单实现：取长度适中的不重复词组
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 && $0.count <= 8 }
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        var unique: [String] = []
        for word in words {
            if !unique.contains(word) { unique.append(word) }
        }
        return Array(unique.prefix(6))
    }

    // MARK: - 答案校验（模糊匹配）
    public func checkAnswer(userAnswer: String, correctAnswer: String,
                             type: QuestionType) -> Bool {
        let user = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correct = correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch type {
        case .multipleChoice, .trueFalse:
            return user == correct
        case .fillInBlank:
            return user == correct || correct.contains(user) || user.contains(correct)
        case .shortAnswer:
            // 简单关键词匹配
            let correctWords = Set(correct.split(separator: " "))
            let userWords = Set(user.split(separator: " "))
            let overlap = correctWords.intersection(userWords)
            return Double(overlap.count) / Double(max(correctWords.count, 1)) > 0.3
        }
    }
}
