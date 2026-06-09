import Foundation

// MARK: - 用户模型
struct User: Identifiable, Codable, Equatable {
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
    var cognitiveProfile: CognitiveProfile?

    /// 用户是否已完成初始化设置
    var isProfileComplete: Bool {
        !name.isEmpty && learningGoal != nil
    }

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
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
struct KnowledgeNode: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var tags: [String]
    var category: KnowledgeCategory
    var difficulty: DifficultyLevel
    var createdAt: Date
    var lastReviewedAt: Date?
    var reviewCount: Int
    var relatedNodes: [RelatedNode]
    var forgettingCurve: ForgettingCurve?
    var masteryLevel: Double
    /// SM-2 算法参数
    var sm2Data: SM2Data

    /// 复习历史记录（最近 30 次）
    var reviewHistory: [ReviewRecord]

    /// 距离上次复习的天数
    var daysSinceLastReview: Int {
        guard let lastReview = lastReviewedAt else {
            return Int(Date().timeIntervalSince(createdAt) / 86400)
        }
        return Int(Date().timeIntervalSince(lastReview) / 86400)
    }

    /// 是否需要紧急复习（风险高危 + 距上次复习超过推荐间隔）
    var needsUrgentReview: Bool {
        guard let curve = forgettingCurve else { return false }
        return curve.riskLevel == .critical || curve.riskLevel == .warning
    }

    struct RelatedNode: Codable, Equatable {
        let nodeId: UUID
        let relationship: RelationshipType
        /// 关系强度 0~1
        let strength: Double

        static func == (lhs: RelatedNode, rhs: RelatedNode) -> Bool {
            lhs.nodeId == rhs.nodeId && lhs.relationship == rhs.relationship
        }
    }

    /// SM-2 间隔重复算法数据
    struct SM2Data: Codable, Equatable {
        /// 复习间隔（天）
        var interval: Double = 1.0
        /// 容易度因子 (E-Factor)，初始 2.5，范围 1.3~2.5
        var easinessFactor: Double = 2.5
        /// 连续正确次数
        var consecutiveCorrect: Int = 0
        /// 下次复习日期
        var nextReviewDate: Date = Date().addingTimeInterval(86400)
    }

    /// 单次复习记录
    struct ReviewRecord: Codable, Equatable {
        let date: Date
        let quality: ReviewQuality
        let durationSeconds: TimeInterval

        enum ReviewQuality: Int, Codable {
            case completeBlackout = 0  // 完全忘记
            case incorrectRecall = 1   // 错误但看到答案后想起
            case incorrectEasy = 2     // 错误但觉得答案简单
            case correctDifficult = 3  // 正确但很困难
            case correctHesitant = 4   // 正确但有犹豫
            case perfect = 5           // 完美回忆
        }
    }
}

enum KnowledgeCategory: String, Codable, CaseIterable {
    case concept = "概念"
    case principle = "原理"
    case procedure = "过程"
    case fact = "事实"
    case skill = "技能"
}

enum DifficultyLevel: String, Codable, CaseIterable, Comparable {
    case beginner = "入门"
    case elementary = "基础"
    case intermediate = "中级"
    case advanced = "高级"
    case expert = "专家"

    var numericValue: Double {
        switch self {
        case .beginner: return 0.2
        case .elementary: return 0.4
        case .intermediate: return 0.6
        case .advanced: return 0.8
        case .expert: return 1.0
        }
    }

    static func < (lhs: DifficultyLevel, rhs: DifficultyLevel) -> Bool {
        lhs.numericValue < rhs.numericValue
    }
}

enum RelationshipType: String, Codable, CaseIterable {
    case prerequisite = "前置知识"
    case extension_ = "扩展"
    case related = "相关"
    case opposite = "对比"
    case application = "应用"
}

// MARK: - 遗忘曲线模型
struct ForgettingCurve: Codable, Equatable {
    let nodeId: UUID
    /// 记忆衰减常数 S (越大遗忘越慢)
    let decayConstant: Double
    /// 基线保留率（长期记忆）
    let baselineRetention: Double
    /// 当前保留率 (0~1)
    let retentionRate: Double
    /// 预测遗忘到 30% 的时间点
    let predictedForgottenAt: Date
    /// 最佳复习时间（保留率降至 60%）
    let optimalReviewTime: Date
    /// 风险等级
    let riskLevel: RiskLevel
    /// 预测生成时间
    let predictedAt: Date

    enum RiskLevel: String, Codable, CaseIterable {
        case critical = "高危"
        case warning = "警告"
        case moderate = "中等"
        case good = "良好"
        case excellent = "优秀"

        /// 触发该风险等级的掌握度阈值（≤ 此值进入该等级）
        static func level(for mastery: Double) -> RiskLevel {
            switch mastery {
            case ..<0.3: return .critical
            case ..<0.5: return .warning
            case ..<0.7: return .moderate
            case ..<0.9: return .good
            default: return .excellent
            }
        }
    }
}

// MARK: - 复习模型
struct ReviewPlan: Identifiable, Codable {
    let id: UUID
    let date: Date
    var items: [ReviewItem]
    var isCompleted: Bool
    var score: Double?
    /// 计划复习总数
    var totalTarget: Int
    /// 实际完成数
    var completedCount: Int {
        items.filter { $0.isCorrect != nil }.count
    }
    /// 正确率
    var accuracy: Double {
        let answered = items.filter { $0.isCorrect != nil }
        guard !answered.isEmpty else { return 0 }
        return Double(answered.filter { $0.isCorrect == true }.count) / Double(answered.count)
    }
}

struct ReviewItem: Identifiable, Codable, Equatable {
    let id: UUID
    let nodeId: UUID
    let questionType: QuestionType
    let question: String
    let options: [String]?
    let correctAnswer: String
    var userAnswer: String?
    var isCorrect: Bool?
    /// 用户答题用时（秒）
    var responseTimeSeconds: TimeInterval?

    static func == (lhs: ReviewItem, rhs: ReviewItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum QuestionType: String, Codable, CaseIterable {
    case multipleChoice = "选择题"
    case trueFalse = "判断题"
    case fillInBlank = "填空题"
    case shortAnswer = "问答题"
}

// MARK: - 认知画像
struct CognitiveProfile: Codable, Equatable {
    /// 学习总时长（小时）
    var totalStudyHours: Double
    /// 知识增长率（每周新增知识点）
    var weeklyGrowthRate: Double
    /// 记忆保持率 (加权平均)
    var retentionRate: Double
    /// 复习完成率
    var reviewCompletionRate: Double
    /// 综合掌握度 (所有节点加权平均)
    var overallMastery: Double
    /// 学习连续天数
    var consecutiveDays: Int
    /// 总知识点数
    var totalNodes: Int
    /// 本周复习次数
    var reviewsThisWeek: Int

    /// 优势领域 (掌握度前 3)
    var strengths: [KnowledgeCategory]
    /// 薄弱领域 (掌握度后 3)
    var weaknesses: [KnowledgeCategory]
    /// 学习偏好（根据答题数据推断）
    var learningPreference: LearningPreference
    /// 历史趋势
    var history: [ProfileSnapshot]

    enum LearningPreference: String, Codable {
        case visual = "视觉型"
        case textual = "文本型"
        case interactive = "互动型"
        case balanced = "均衡型"
    }
}

struct ProfileSnapshot: Codable, Equatable {
    let date: Date
    let totalNodes: Int
    let averageMastery: Double
    let retentionRate: Double
    let reviewsCompleted: Int
}

// MARK: - 知识树节点
struct KnowledgeTreeNode: Identifiable, Codable {
    let id: UUID
    let node: KnowledgeNode
    var children: [KnowledgeTreeNode]
    /// 树的深度
    let depth: Int
    /// 该节点在树中的权重
    var weight: Double
}

// MARK: - API 响应模型
struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let tokenType: String

    var isExpired: Bool {
        Date() > expiresAt
    }
}

struct APIError: Codable, Error {
    let code: Int
    let message: String
    let details: String?
}

// MARK: - 搜索/筛选模型
struct SearchQuery {
    var keyword: String = ""
    var categories: [KnowledgeCategory] = []
    var difficultyRange: ClosedRange<Double> = 0...1
    var masteryRange: ClosedRange<Double> = 0...1
    var riskLevels: [ForgettingCurve.RiskLevel] = []
    var tags: [String] = []
    var sortBy: SortOption = .relevance

    enum SortOption: String, CaseIterable {
        case relevance = "相关度"
        case newest = "最新"
        case oldest = "最早"
        case masteryLow = "掌握度低优先"
        case masteryHigh = "掌握度高优先"
        case urgent = "紧急复习优先"
    }

    var isEmpty: Bool {
        keyword.isEmpty && categories.isEmpty && tags.isEmpty
    }
}
