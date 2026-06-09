import XCTest
@testable import MindEchoCore

final class ForgettingCurveEngineTests: XCTestCase {

    // MARK: - 艾宾浩斯遗忘曲线测试
    func testEbbinghausRetention_zeroElapsed_shouldReturnOne() {
        // 刚学完时，保留率应为 100%
        let retention = ForgettingCurveEngine.ebbinghausRetention(
            elapsedHours: 0,
            strength: 24.0
        )
        XCTAssertEqual(retention, 1.0, accuracy: 0.001)
    }

    func testEbbinghausRetention_oneDayElapsed_shouldDecrease() {
        // 24小时后，保留率应下降
        let retention = ForgettingCurveEngine.ebbinghausRetention(
            elapsedHours: 24,
            strength: 24.0
        )
        XCTAssertEqual(retention, exp(-1.0), accuracy: 0.001)
    }

    func testEbbinghausRetention_higherStrength_shouldRetainMore() {
        // 记忆强度越高，遗忘越慢
        let weakRetention = ForgettingCurveEngine.ebbinghausRetention(
            elapsedHours: 48,
            strength: 24.0
        )
        let strongRetention = ForgettingCurveEngine.ebbinghausRetention(
            elapsedHours: 48,
            strength: 48.0
        )
        XCTAssertGreaterThan(strongRetention, weakRetention)
    }

    // MARK: - 风险等级测试
    func testAssessRisk_criticalLevel() {
        let risk = ForgettingCurveEngine.assessRisk(mastery: 0.2, retentionRate: 0.3)
        XCTAssertEqual(risk, .critical)
    }

    func testAssessRisk_excellentLevel() {
        let risk = ForgettingCurveEngine.assessRisk(mastery: 0.95, retentionRate: 0.9)
        XCTAssertEqual(risk, .excellent)
    }

    // MARK: - 最佳复习时间测试
    func testOptimalReviewTime_shouldBeInTheFuture() {
        let node = KnowledgeNode(
            id: UUID(),
            title: "Test Node",
            content: "Test Content",
            tags: ["test"],
            category: .concept,
            difficulty: .intermediate,
            createdAt: Date(),
            lastReviewedAt: nil,
            reviewCount: 0,
            relatedNodes: [],
            forgettingCurve: nil,
            masteryLevel: 0.5
        )
        let optimalTime = ForgettingCurveEngine.calculateOptimalReviewTime(
            for: node,
            strength: 24.0
        )
        XCTAssertGreaterThan(optimalTime, Date())
    }
}

final class KnowledgeGraphEngineTests: XCTestCase {

    var engine: KnowledgeGraphEngine!

    override func setUp() {
        super.setUp()
        engine = KnowledgeGraphEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - 节点添加测试
    func testAddNode_shouldStoreNodeCorrectly() {
        let node = makeNode(id: UUID(), title: "Swift Basics")
        engine.addNode(node)

        // 通过路径搜索验证节点存在
        let path = engine.findShortestPath(from: node.id, to: node.id)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.count, 1)
    }

    // MARK: - 路径搜索测试
    func testFindShortestPath_directConnection_shouldReturnTwoNodes() {
        let nodeA = makeNode(id: UUID(), title: "A")
        let nodeB = makeNode(id: UUID(), title: "B")

        engine.addNode(nodeA)
        engine.addNode(nodeB)
        engine.addEdge(from: nodeA.id, to: nodeB.id)

        let path = engine.findShortestPath(from: nodeA.id, to: nodeB.id)
        XCTAssertNotNil(path)
        XCTAssertEqual(path, [nodeA.id, nodeB.id])
    }

    func testFindShortestPath_noConnection_shouldReturnNil() {
        let nodeA = makeNode(id: UUID(), title: "A")
        let nodeB = makeNode(id: UUID(), title: "B")

        engine.addNode(nodeA)
        engine.addNode(nodeB)

        let path = engine.findShortestPath(from: nodeA.id, to: nodeB.id)
        XCTAssertNil(path)
    }

    func testFindShortestPath_indirectConnection_shouldReturnFullPath() {
        let nodeA = makeNode(id: UUID(), title: "A")
        let nodeB = makeNode(id: UUID(), title: "B")
        let nodeC = makeNode(id: UUID(), title: "C")

        engine.addNode(nodeA)
        engine.addNode(nodeB)
        engine.addNode(nodeC)
        engine.addEdge(from: nodeA.id, to: nodeB.id)
        engine.addEdge(from: nodeB.id, to: nodeC.id)

        let path = engine.findShortestPath(from: nodeA.id, to: nodeC.id)
        XCTAssertNotNil(path)
        XCTAssertEqual(path, [nodeA.id, nodeB.id, nodeC.id])
    }

    // MARK: - 聚类测试
    func testClusterNodes_disconnectedNodes_shouldClusterIndependently() {
        let nodeA = makeNode(id: UUID(), title: "A")
        let nodeB = makeNode(id: UUID(), title: "B")
        let nodeC = makeNode(id: UUID(), title: "C")

        engine.addNode(nodeA)
        engine.addNode(nodeB)
        engine.addNode(nodeC)
        engine.addEdge(from: nodeA.id, to: nodeB.id)
        // nodeC 独立

        let clusters = engine.clusterNodes()
        XCTAssertEqual(clusters.count, 2, "AB 一个群，C 单独一个群")
    }

    // MARK: - 关联推荐测试
    func testSuggestConnections_shouldRankBySimilarity() {
        let nodeA = KnowledgeNode(
            id: UUID(), title: "Swift Basics",
            content: "", tags: ["swift", "programming", "ios"],
            category: .concept, difficulty: .beginner,
            createdAt: Date(), lastReviewedAt: nil, reviewCount: 0,
            relatedNodes: [], forgettingCurve: nil, masteryLevel: 1.0
        )
        let nodeB = KnowledgeNode(
            id: UUID(), title: "SwiftUI",
            content: "", tags: ["swift", "swiftui", "ios"],
            category: .concept, difficulty: .beginner,
            createdAt: Date(), lastReviewedAt: nil, reviewCount: 0,
            relatedNodes: [], forgettingCurve: nil, masteryLevel: 1.0
        )
        let nodeC = KnowledgeNode(
            id: UUID(), title: "Machine Learning",
            content: "", tags: ["ml", "ai", "python"],
            category: .skill, difficulty: .advanced,
            createdAt: Date(), lastReviewedAt: nil, reviewCount: 0,
            relatedNodes: [], forgettingCurve: nil, masteryLevel: 1.0
        )

        engine.addNode(nodeA)
        engine.addNode(nodeB)
        engine.addNode(nodeC)

        let suggestions = engine.suggestConnections(for: nodeA.id, topK: 2)
        // nodeB (共享 2 个标签) 应该排在 nodeC (0 个标签) 前面
        if suggestions.count >= 1 {
            XCTAssertEqual(suggestions[0], nodeB.id)
        }
    }

    // MARK: - Helpers
    private func makeNode(id: UUID, title: String) -> KnowledgeNode {
        KnowledgeNode(
            id: id,
            title: title,
            content: "Test content for \(title)",
            tags: ["test"],
            category: .concept,
            difficulty: .beginner,
            createdAt: Date(),
            lastReviewedAt: nil,
            reviewCount: 0,
            relatedNodes: [],
            forgettingCurve: nil,
            masteryLevel: 1.0
        )
    }
}

final class ModelsTests: XCTestCase {

    func testDifficultyLevel_allCasesExist() {
        XCTAssertEqual(DifficultyLevel.allCases.count, 5)
    }

    func testKnowledgeCategory_allCasesExist() {
        XCTAssertEqual(KnowledgeCategory.allCases.count, 5)
    }

    func testQuestionType_allCasesExist() {
        XCTAssertEqual(QuestionType.allCases.count, 4)
    }

    func testRelationshipType_allCasesExist() {
        XCTAssertEqual(RelationshipType.allCases.count, 5)
    }

    func testUser_codableRoundTrip() throws {
        let user = User(
            id: UUID(),
            name: "Test User",
            email: "test@mindecho.local",
            phone: nil,
            avatarURL: nil,
            learningDirection: .computerScience,
            targetExam: nil,
            learningGoal: "Master iOS development",
            createdAt: Date(),
            lastLoginAt: Date(),
            cognitiveProfile: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(user)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(User.self, from: data)

        XCTAssertEqual(decoded.name, user.name)
        XCTAssertEqual(decoded.email, user.email)
        XCTAssertEqual(decoded.learningDirection, user.learningDirection)
    }
}
