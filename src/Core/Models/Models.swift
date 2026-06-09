import Foundation

// MARK: - 用户模型
/// 用户核心数据模型
struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var phone: String?
    var avatarURL: URL?
    var learningDirection: LearningDirection
    var targetExam: String?
    var learningGoal: String?
    var createdAt: Date
    var lastLoginAt: Date

    /// 用户认知画像（由系统自动生成）
    var cognitiveProfile: CognitiveProfile?
}

enum LearningDirection: String, Codable, CaseIterable {
    case computerScience = "计算机科学"
    case mathematics = "数学"
    case physics = "物理"
    case literature = "文学"
    case history = "历史"
    case foreignLanguage = "外语"
    case professionalCertification = "职业认证"
    case other = "其他"
}

// MARK: - 知识点模型
/// 知识节点 — 记忆图谱的基本单元
struct KnowledgeNode: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var tags: [String]
    var category: KnowledgeCategory
    var difficulty: DifficultyLevel
    var createdAt: Date
    var lastReviewedAt: Date?
    var reviewCount: Int

    /// 关联的知识节点 ID 及关系强度
    var relatedNodes: [RelatedNode]
    /// 遗忘曲线参数（由 ML 模型计算）
    var forgettingCurve: ForgettingCurve?
    /// 当前掌握度 (0.0 ~ 1.0)
    var masteryLevel: Double

    struct RelatedNode: Codable {
        let nodeId: UUID
        let relationship: RelationshipType
        let strength: Double
    }
}

enum KnowledgeCategory: String, Codable, CaseIterable {
    case concept = "概念"
    case principle = "原理"
    case procedure = "过程"
    case fact = "事实"
    case skill = "技能"
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner = "入门"
    case elementary = "基础"
    case intermediate = "中级"
    case advanced = "高级"
    case expert = "专家"
}

enum RelationshipType: String, Codable, CaseIterable {
    case prerequisite = "前置知识"
    case extension_ = "扩展"
    case related = "相关"
    case opposite = "对比"
    case application = "应用"
}

// MARK: - 遗忘曲线模型
/// 基于艾宾浩斯遗忘曲线与机器学习预测
struct ForgettingCurve: Codable {
    let nodeId: UUID
    /// 遗忘曲线参数 (a, b, c) 对应 R = e^(-t/a) * b + c
    let paramA: Double
    let paramB: Double
    let paramC: Double
    /// 预测的遗忘时间点
    let predictedForgottenAt: Date
    /// 当前保留率 (0.0 ~ 1.0)
    let retentionRate: Double
    /// 最佳复习时间点
    let optimalReviewTime: Date
    /// 风险等级
    let riskLevel: RiskLevel

    enum RiskLevel: String, Codable {
        case critical = "高危"    // 掌握度 < 0.3
        case warning = "警告"     // 掌握度 < 0.5
        case moderate = "中等"    // 掌握度 < 0.7
        case good = "良好"       // 掌握度 >= 0.7
        case excellent = "优秀"   // 掌握度 >= 0.9
    }
}

// MARK: - 复习模型
struct ReviewPlan: Identifiable, Codable {
    let id: UUID
    let date: Date
    var items: [ReviewItem]
    var isCompleted: Bool
    var score: Double?
}

struct ReviewItem: Identifiable, Codable {
    let id: UUID
    let nodeId: UUID
    let questionType: QuestionType
    let question: String
    let options: [String]?
    let correctAnswer: String
    var userAnswer: String?
    var isCorrect: Bool?
}

enum QuestionType: String, Codable, CaseIterable {
    case multipleChoice = "选择题"
    case trueFalse = "判断题"
    case fillInBlank = "填空题"
    case shortAnswer = "问答题"
}

// MARK: - 认知画像
struct CognitiveProfile: Codable {
    /// 学习总时长（小时）
    var totalStudyHours: Double
    /// 知识增长率（每周新增知识点）
    var weeklyGrowthRate: Double
    /// 记忆保持率
    var retentionRate: Double
    /// 复习完成率
    var reviewCompletionRate: Double
    /// 综合掌握度
    var overallMastery: Double

    /// 优势领域
    var strengths: [KnowledgeCategory]
    /// 薄弱领域
    var weaknesses: [KnowledgeCategory]
    /// 历史趋势数据
    var history: [ProfileSnapshot]
}

struct ProfileSnapshot: Codable {
    let date: Date
    let totalNodes: Int
    let averageMastery: Double
    let retentionRate: Double
}
