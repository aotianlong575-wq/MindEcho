import XCTest
@testable import MindEchoCore

// MARK: - Helpers
extension KnowledgeNode {
    static func stub(id: UUID = UUID(), title: String = "Test", content: String = "Content",
                     tags: [String] = ["test"], category: KnowledgeCategory = .concept,
                     difficulty: DifficultyLevel = .intermediate,
                     mastery: Double = 0.5, reviewCount: Int = 0) -> KnowledgeNode {
        KnowledgeNode(
            id: id, title: title, content: content, tags: tags,
            category: category, difficulty: difficulty,
            createdAt: Date(), lastReviewedAt: nil, reviewCount: reviewCount,
            relatedNodes: [], forgettingCurve: nil, masteryLevel: mastery,
            sm2Data: .init(), reviewHistory: []
        )
    }
}

// ============================================================
// MARK: - ForgettingCurveEngine 测试
// ============================================================
final class ForgettingCurveEngineTests: XCTestCase {

    func testRetention_zeroElapsed_returnsOne() {
        let r = ForgettingCurveEngine.ebbinghausRetention(elapsedHours: 0, strengthHours: 24)
        XCTAssertEqual(r, 1.0, accuracy: 0.001)
    }

    func testRetention_oneDayLater_shouldDecrease() {
        let r = ForgettingCurveEngine.ebbinghausRetention(elapsedHours: 24, strengthHours: 24)
        XCTAssertEqual(r, exp(-1.0) * 0.95 + 0.05, accuracy: 0.01)
    }

    func testRetention_strongerMemory_retainsMore() {
        let weak = ForgettingCurveEngine.ebbinghausRetention(elapsedHours: 48, strengthHours: 24)
        let strong = ForgettingCurveEngine.ebbinghausRetention(elapsedHours: 48, strengthHours: 48)
        XCTAssertGreaterThan(strong, weak)
    }

    func testSM2_perfectAnswer_increasesInterval() {
        var sm2 = KnowledgeNode.SM2Data()
        let updated = ForgettingCurveEngine.sm2Update(sm2Data: sm2, quality: .perfect)
        XCTAssertEqual(updated.interval, 1.0)
        XCTAssertEqual(updated.consecutiveCorrect, 1)
    }

    func testSM2_threeCorrect_usesEasinessFactor() {
        var sm2 = KnowledgeNode.SM2Data()
        sm2.consecutiveCorrect = 1
        sm2.interval = 6.0
        let updated = ForgettingCurveEngine.sm2Update(sm2Data: sm2, quality: .correctDifficult)
        XCTAssertGreaterThan(updated.interval, 1.0)
    }

    func testSM2_wrongAnswer_resetsInterval() {
        var sm2 = KnowledgeNode.SM2Data()
        sm2.interval = 10.0
        sm2.consecutiveCorrect = 3
        let updated = ForgettingCurveEngine.sm2Update(sm2Data: sm2, quality: .completeBlackout)
        XCTAssertEqual(updated.consecutiveCorrect, 0)
        XCTAssertLessThan(updated.interval, 10.0)
    }

    func testUpdateMastery_perfectAnswer_improvesMastery() {
        let new = ForgettingCurveEngine.updateMastery(currentMastery: 0.5, quality: .perfect)
        XCTAssertGreaterThan(new, 0.6)
    }

    func testUpdateMastery_blackout_decreasesMastery() {
        let new = ForgettingCurveEngine.updateMastery(currentMastery: 0.8, quality: .completeBlackout)
        XCTAssertLessThan(new, 0.7)
    }

    func testGenerateReviewPlan_returnsItemsWithinLimit() {
        let nodes = (0..<30).map { KnowledgeNode.stub(title: "Node \($0)", mastery: Double($0) / 30) }
        let plan = ForgettingCurveEngine.generateReviewPlan(for: nodes, maxItems: 10)
        XCTAssertLessThanOrEqual(plan.items.count, 10)
    }
}

// ============================================================
// MARK: - KnowledgeGraphEngine 测试
// ============================================================
final class KnowledgeGraphEngineTests: XCTestCase {
    var engine: KnowledgeGraphEngine!

    override func setUp() { super.setUp(); engine = KnowledgeGraphEngine() }
    override func tearDown() { engine = nil; super.tearDown() }

    func testAddNode_storesNode() {
        let n = KnowledgeNode.stub()
        engine.addNode(n)
        XCTAssertEqual(engine.nodeCount, 1)
    }

    func testAddEdge_createsBidirectionalConnection() {
        let a = KnowledgeNode.stub(id: UUID(), title: "A")
        let b = KnowledgeNode.stub(id: UUID(), title: "B")
        engine.addNode(a); engine.addNode(b)
        engine.addEdge(from: a.id, to: b.id)
        XCTAssertEqual(engine.edgeCount, 1)
    }

    func testShortestPath_directEdge_returnsTwoNodes() {
        let a = KnowledgeNode.stub(id: UUID(), title: "A")
        let b = KnowledgeNode.stub(id: UUID(), title: "B")
        engine.addNode(a); engine.addNode(b)
        engine.addEdge(from: a.id, to: b.id)
        let path = engine.findShortestPath(from: a.id, to: b.id)
        XCTAssertEqual(path, [a.id, b.id])
    }

    func testShortestPath_noConnection_returnsNil() {
        let a = KnowledgeNode.stub(id: UUID(), title: "A")
        let b = KnowledgeNode.stub(id: UUID(), title: "B")
        engine.addNode(a); engine.addNode(b)
        XCTAssertNil(engine.findShortestPath(from: a.id, to: b.id))
    }

    func testShortestPath_threeNodes_returnsFullPath() {
        let a = KnowledgeNode.stub(id: UUID(), title: "A")
        let b = KnowledgeNode.stub(id: UUID(), title: "B")
        let c = KnowledgeNode.stub(id: UUID(), title: "C")
        engine.addNode(a); engine.addNode(b); engine.addNode(c)
        engine.addEdge(from: a.id, to: b.id)
        engine.addEdge(from: b.id, to: c.id)
        let path = engine.findShortestPath(from: a.id, to: c.id)
        XCTAssertEqual(path, [a.id, b.id, c.id])
    }

    func testConnectedComponents_disconnectedNodes() {
        let a = KnowledgeNode.stub(id: UUID(), title: "A")
        let b = KnowledgeNode.stub(id: UUID(), title: "B")
        let c = KnowledgeNode.stub(id: UUID(), title: "C")
        engine.addNode(a); engine.addNode(b); engine.addNode(c)
        engine.addEdge(from: a.id, to: b.id)
        let comps = engine.connectedComponents()
        XCTAssertEqual(comps.count, 2) // AB 连通，C 独立
    }

    func testPageRank_returnsAllNodes() {
        let a = KnowledgeNode.stub(id: UUID(), title: "A")
        let b = KnowledgeNode.stub(id: UUID(), title: "B")
        engine.addNode(a); engine.addNode(b)
        engine.addEdge(from: a.id, to: b.id)
        let ranks = engine.pageRank()
        XCTAssertEqual(ranks.count, 2)
    }

    func testSuggestConnections_prefersSimilarTags() {
        let swift = KnowledgeNode.stub(id: UUID(), title: "Swift", tags: ["swift", "ios", "lang"])
        let swiftui = KnowledgeNode.stub(id: UUID(), title: "SwiftUI", tags: ["swift", "swiftui", "ios"])
        let python = KnowledgeNode.stub(id: UUID(), title: "Python", tags: ["python", "ml"])
        engine.addNode(swift); engine.addNode(swiftui); engine.addNode(python)

        let suggestions = engine.suggestConnections(for: swift.id, topK: 2)
        XCTAssertEqual(suggestions.first, swiftui.id)
    }
}

// ============================================================
// MARK: - UserManager 测试
// ============================================================
final class UserManagerTests: XCTestCase {
    @MainActor
    func testLoginEmail_invalidEmail_throwsError() async {
        let vm = UserManager()
        do {
            try await vm.loginWithEmail(email: "notanemail", password: "123456")
            XCTFail("Expected error")
        } catch UserError.invalidEmail {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    @MainActor
    func testLoginEmail_shortPassword_throwsError() async {
        let vm = UserManager()
        do {
            try await vm.loginWithEmail(email: "a@b.com", password: "123")
            XCTFail("Expected error")
        } catch UserError.passwordTooShort {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    @MainActor
    func testLoginEmail_validCredentials_setsUser() async throws {
        let vm = UserManager()
        try await vm.loginWithEmail(email: "user@mindecho.local", password: "password123")
        XCTAssertTrue(vm.isAuthenticated)
        XCTAssertNotNil(vm.currentUser)
    }

    @MainActor
    func testLogout_clearsUser() async throws {
        let vm = UserManager()
        try await vm.loginWithEmail(email: "u@b.com", password: "123456")
        vm.logout()
        XCTAssertFalse(vm.isAuthenticated)
        XCTAssertNil(vm.currentUser)
    }
}

// ============================================================
// MARK: - OCRService 测试
// ============================================================
final class OCRServiceTests: XCTestCase {
    func testExtractKeywords_returnsNonEmpty() {
        let svc = OCRService()
        let keywords = svc.extractKeywords(from: "人工智能是计算机科学的一个分支")
        XCTAssertFalse(keywords.isEmpty)
    }

    func testExtractKnowledgeNodes_returnsCandidates() async throws {
        let svc = OCRService()
        let text = "机器学习是人工智能的一个分支。深度学习使用神经网络进行模式识别。"
        let candidates = try await svc.extractKnowledgeNodes(from: text)
        XCTAssertFalse(candidates.isEmpty)
    }

    func testClassifyCategory_procedureText_returnsProcedure() {
        let svc = OCRService()
        let cat = svc.classifyCategory(for: "操作步骤如下：第一步准备环境，第二步执行流程")
        XCTAssertEqual(cat, .procedure)
    }

    func testClassifyCategory_conceptText_returnsConcept() {
        let svc = OCRService()
        let cat = svc.classifyCategory(for: "机器学习是指让计算机从数据中学习规律的方法")
        XCTAssertEqual(cat, .concept)
    }

    func testEstimateDifficulty_shortSimpleText_returnsBeginner() {
        let svc = OCRService()
        let diff = svc.estimateDifficulty(for: "猫是一种动物")
        XCTAssertEqual(diff, .beginner)
    }

    func testEstimateDifficulty_technicalText_returnsHigher() {
        let svc = OCRService()
        let diff = svc.estimateDifficulty(for: "神经网络反向传播算法通过链式法则计算梯度更新模型参数")
        XCTAssertGreaterThanOrEqual(diff, .intermediate)
    }
}

// ============================================================
// MARK: - QuestionGenerator 测试
// ============================================================
final class QuestionGeneratorTests: XCTestCase {
    func testGenerateMultipleChoice_hasFourOptions() {
        let gen = QuestionGenerator()
        let node = KnowledgeNode.stub(title: "Swift", content: "Swift is a programming language for iOS development using modern syntax", tags: ["swift", "ios"])
        let item = gen.generateQuestion(for: node, type: .multipleChoice)
        XCTAssertEqual(item.questionType, .multipleChoice)
        XCTAssertEqual(item.options?.count, 4)
    }

    func testGenerateTrueFalse_hasCorrectFormat() {
        let gen = QuestionGenerator()
        let node = KnowledgeNode.stub(category: .fact, content: "The sky is blue")
        let item = gen.generateQuestion(for: node, type: .trueFalse)
        XCTAssertEqual(item.questionType, .trueFalse)
        XCTAssertNotNil(item.options)
    }

    func testGenerateFillInBlank_masksKeyword() {
        let gen = QuestionGenerator()
        let node = KnowledgeNode.stub(title: "Variable", content: "A variable stores data in memory", tags: ["variable"])
        let item = gen.generateQuestion(for: node, type: .fillInBlank)
        XCTAssertEqual(item.questionType, .fillInBlank)
    }

    func testGenerateQuestions_batch_returnsCorrectCount() {
        let gen = QuestionGenerator()
        let nodes = (0..<5).map { KnowledgeNode.stub(title: "Node \($0)") }
        let items = gen.generateQuestions(for: nodes)
        XCTAssertEqual(items.count, 5)
    }

    func testCheckAnswer_multipleChoice_exactMatch() {
        let gen = QuestionGenerator()
        XCTAssertTrue(gen.checkAnswer(userAnswer: "B", correctAnswer: "B", type: .multipleChoice))
        XCTAssertFalse(gen.checkAnswer(userAnswer: "A", correctAnswer: "B", type: .multipleChoice))
    }

    func testCheckAnswer_fillInBlank_fuzzyMatch() {
        let gen = QuestionGenerator()
        XCTAssertTrue(gen.checkAnswer(userAnswer: "神经网络", correctAnswer: "神经网络", type: .fillInBlank))
    }
}

// ============================================================
// MARK: - CognitiveProfileEngine 测试
// ============================================================
final class CognitiveProfileEngineTests: XCTestCase {
    func testEmptyProfile_noNodes_returnsZeros() {
        let profile = CognitiveProfileEngine.generateProfile(nodes: [])
        XCTAssertEqual(profile.totalNodes, 0)
        XCTAssertEqual(profile.overallMastery, 0)
    }

    func testProfile_withNodes_calculatesMastery() {
        let nodes = [
            KnowledgeNode.stub(mastery: 0.8, reviewCount: 3),
            KnowledgeNode.stub(mastery: 0.6, reviewCount: 1),
            KnowledgeNode.stub(mastery: 0.4, reviewCount: 0)
        ]
        let profile = CognitiveProfileEngine.generateProfile(nodes: nodes)
        XCTAssertEqual(profile.totalNodes, 3)
        XCTAssertGreaterThan(profile.overallMastery, 0)
    }

    func testMasteryByCategory_groupsCorrectly() {
        let nodes = [
            KnowledgeNode.stub(category: .concept, mastery: 0.9),
            KnowledgeNode.stub(category: .concept, mastery: 0.7),
            KnowledgeNode.stub(category: .skill, mastery: 0.5)
        ]
        let mastery = CognitiveProfileEngine.masteryByCategory(nodes)
        XCTAssertEqual(mastery[.concept], 0.8, accuracy: 0.01)
        XCTAssertEqual(mastery[.skill], 0.5, accuracy: 0.01)
    }

    func testOverallScore_perfectProfile_returnsHighScore() {
        let profile = CognitiveProfile(
            totalStudyHours: 100, weeklyGrowthRate: 0.5, retentionRate: 0.95,
            reviewCompletionRate: 0.9, overallMastery: 0.95,
            consecutiveDays: 30, totalNodes: 200, reviewsThisWeek: 50,
            strengths: [.concept], weaknesses: [],
            learningPreference: .interactive, history: []
        )
        let score = CognitiveProfileEngine.overallScore(for: profile)
        XCTAssertGreaterThan(score, 80)
    }

    func testCommentary_returnsNonEmptyString() {
        let profile = CognitiveProfileEngine.emptyProfile()
        let commentary = CognitiveProfileEngine.generateCommentary(for: profile)
        XCTAssertFalse(commentary.isEmpty)
    }
}

// ============================================================
// MARK: - AIKnowledgeParser 测试
// ============================================================
final class AIKnowledgeParserTests: XCTestCase {
    func testParse_text_returnsNodes() async throws {
        let parser = AIKnowledgeParser()
        let result = try await parser.parse(text: """
        机器学习是人工智能的一个分支，它使用算法从数据中学习。
        深度学习使用多层神经网络进行模式识别。
        监督学习需要标注数据，无监督学习不需要标注数据。
        """)
        XCTAssertFalse(result.nodes.isEmpty)
    }

    func testDiscoverRelations_similarNodes_findsConnections() {
        let parser = AIKnowledgeParser()
        let nodes = [
            KnowledgeNode.stub(id: UUID(), title: "AI", tags: ["ai", "tech"]),
            KnowledgeNode.stub(id: UUID(), title: "ML", tags: ["ai", "ml", "tech"]),
            KnowledgeNode.stub(id: UUID(), title: "Gardening", tags: ["plants", "hobby"])
        ]
        let relations = parser.discoverRelations(among: nodes)
        // AI 和 ML 标签重叠多，应该有较强关联
        XCTAssertFalse(relations.isEmpty)
    }

    func testEvaluateDifficulty_longTechnicalText_returnsHigher() {
        let parser = AIKnowledgeParser()
        let diff = parser.evaluateDifficulty(
            content: "神经网络反向传播算法通过链式法则计算损失函数对各层参数的梯度，然后使用梯度下降优化器更新权重矩阵",
            tags: ["神经网络", "反向传播", "梯度下降"]
        )
        XCTAssertGreaterThanOrEqual(diff, .intermediate)
    }

    func testGenerateTags_extractsKeywords() {
        let parser = AIKnowledgeParser()
        let tags = parser.generateTags(for: "SwiftUI 使用声明式语法构建 iOS 应用界面")
        XCTAssertFalse(tags.isEmpty)
    }
}
