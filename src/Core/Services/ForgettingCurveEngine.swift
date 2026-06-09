import Foundation

/// 遗忘预测引擎
/// 实现 SM-2 间隔重复算法 + 艾宾浩斯遗忘曲线
/// 用于预测知识保留率、计算最佳复习时间、评估遗忘风险
public final class ForgettingCurveEngine {

    // MARK: - 配置常量
    public struct Config {
        /// 当保留率降至该阈值时触发复习
        public var retentionThreshold: Double = 0.6
        /// 遗忘至 30% 视为"遗忘"
        public var forgottenThreshold: Double = 0.3
        /// 初始记忆强度基数（小时）
        public var baseStrengthHours: Double = 24.0
        /// 最小复习间隔（天）
        public var minIntervalDays: Double = 0.25  // 6 小时
        /// 最大复习间隔（天）
        public var maxIntervalDays: Double = 365.0
        /// 正确的复习对 E-Factor 的奖励
        public var easeBonus: Double = 0.1
        /// 错误的复习对 E-Factor 的惩罚
        public var easePenalty: Double = 0.2
        /// E-Factor 下限
        public var minEaseFactor: Double = 1.3
        /// E-Factor 初始值
        public var initialEaseFactor: Double = 2.5
        /// 难度对记忆强度的衰减系数
        public var difficultyDecayFactor: Double = 0.15
    }

    public static var config = Config()

    // MARK: - 艾宾浩斯遗忘曲线
    /// R(t) = baseline + (1 - baseline) * e^(-t / S)
    /// - Parameters:
    ///   - elapsedHours: 距上次复习的小时数
    ///   - strengthHours: 记忆强度 S（越大遗忘越慢）
    ///   - baseline: 长期基线保留率
    /// - Returns: 预测保留率 0~1
    public static func ebbinghausRetention(
        elapsedHours: Double,
        strengthHours: Double,
        baseline: Double = 0.05
    ) -> Double {
        guard elapsedHours >= 0, strengthHours > 0 else { return 1.0 }
        return baseline + (1.0 - baseline) * exp(-elapsedHours / strengthHours)
    }

    // MARK: - 记忆强度计算
    /// 根据知识点属性和复习历史估算当前记忆强度
    /// - Parameters:
    ///   - node: 知识点
    ///   - sm2Interval: SM-2 算法计算出的间隔（天）
    /// - Returns: 记忆强度（小时）
    public static func calculateStrength(for node: KnowledgeNode, sm2Interval: Double) -> Double {
        // 基础强度
        let base = config.baseStrengthHours

        // 复习次数加成（对数增长，避免无限增大）
        let reviewBonus = 1.0 + log(Double(node.reviewCount) + 1.0) * 0.5

        // 难度衰减（越难忘得越快）
        let difficultyPenalty = 1.0 - node.difficulty.numericValue * config.difficultyDecayFactor

        // SM-2 间隔转换为小时并加权
        let intervalHours = sm2Interval * 24.0
        let intervalWeight = min(intervalHours / base, 3.0)

        return base * reviewBonus * difficultyPenalty * max(intervalWeight, 0.5)
    }

    // MARK: - SM-2 间隔重复算法
    /// SM-2 算法核心：根据复习质量更新间隔和容易度因子
    /// - Parameters:
    ///   - sm2Data: 当前 SM-2 参数
    ///   - quality: 本次复习质量评分 (0-5)
    /// - Returns: 更新后的 SM-2 参数
    public static func sm2Update(
        sm2Data: KnowledgeNode.SM2Data,
        quality: KnowledgeNode.ReviewRecord.ReviewQuality
    ) -> KnowledgeNode.SM2Data {
        var data = sm2Data
        let q = quality.rawValue

        if q >= 3 {
            // 正确：按公式更新
            switch data.consecutiveCorrect {
            case 0:
                data.interval = 1.0
            case 1:
                data.interval = 6.0
            default:
                data.interval = round(data.interval * data.easinessFactor)
            }
            data.consecutiveCorrect += 1
        } else {
            // 错误：重置间隔
            data.interval = config.minIntervalDays
            data.consecutiveCorrect = 0
        }

        // 更新 E-Factor (Easiness Factor)
        let newEF = data.easinessFactor + (0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02))
        data.easinessFactor = max(config.minEaseFactor, newEF)
        data.interval = max(config.minIntervalDays, min(config.maxIntervalDays, data.interval))
        data.nextReviewDate = Date().addingTimeInterval(data.interval * 86400)

        return data
    }

    // MARK: - 掌握度更新
    /// 根据复习结果更新知识掌握度
    /// - Parameters:
    ///   - currentMastery: 当前掌握度 0~1
    ///   - quality: 本次复习质量
    /// - Returns: 更新后的掌握度
    public static func updateMastery(
        currentMastery: Double,
        quality: KnowledgeNode.ReviewRecord.ReviewQuality
    ) -> Double {
        let target: Double
        switch quality {
        case .completeBlackout: target = 0.1
        case .incorrectRecall:  target = 0.25
        case .incorrectEasy:    target = 0.4
        case .correctDifficult: target = 0.65
        case .correctHesitant:  target = 0.8
        case .perfect:          target = 0.95
        }

        // 指数移动平均：新值权重 0.3，旧值权重 0.7
        let alpha = 0.3
        return currentMastery * (1 - alpha) + target * alpha
    }

    // MARK: - 批量预测
    /// 对多个知识点进行遗忘预测
    /// - Parameter nodes: 知识点列表
    /// - Returns: 节点 ID → 遗忘曲线 的映射
    public static func predictForgetting(for nodes: [KnowledgeNode]) -> [UUID: ForgettingCurve] {
        var results: [UUID: ForgettingCurve] = [:]
        let now = Date()

        for node in nodes {
            let elapsedHours = now.timeIntervalSince(node.lastReviewedAt ?? node.createdAt) / 3600
            let strength = calculateStrength(for: node, sm2Interval: node.sm2Data.interval)
            let retention = ebbinghausRetention(elapsedHours: elapsedHours, strengthHours: strength)
            let riskLevel = ForgettingCurve.RiskLevel.level(for: node.masteryLevel)

            // 计算关键时间点
            let optimalHours: Double
            if retention > config.retentionThreshold {
                // 还需要多久降到阈值
                optimalHours = -strength * log((config.retentionThreshold - 0.05) / 0.95)
            } else {
                optimalHours = 0  // 现在就该复习
            }
            let forgottenHours = -strength * log((config.forgottenThreshold - 0.05) / 0.95)

            results[node.id] = ForgettingCurve(
                nodeId: node.id,
                decayConstant: strength,
                baselineRetention: 0.05,
                retentionRate: retention,
                predictedForgottenAt: now.addingTimeInterval(forgottenHours * 3600),
                optimalReviewTime: now.addingTimeInterval(optimalHours * 3600),
                riskLevel: riskLevel,
                predictedAt: now
            )
        }

        return results
    }

    // MARK: - 复习计划生成
    /// 根据遗忘预测生成今日复习计划
    /// - Parameters:
    ///   - nodes: 全部知识点
    ///   - maxItems: 单日最大复习量
    /// - Returns: 复习计划
    public static func generateReviewPlan(
        for nodes: [KnowledgeNode],
        maxItems: Int = 20
    ) -> ReviewPlan {
        let predictions = predictForgetting(for: nodes)
        let now = Date()

        // 筛选需要复习的节点
        let candidates = nodes.filter { node in
            guard let curve = predictions[node.id] else { return false }
            // 今天需要复习 = 保留率已降到阈值以下 或 SM-2 指示今天复习
            return curve.retentionRate < config.retentionThreshold
                || node.sm2Data.nextReviewDate <= now
        }
        // 按紧急程度排序
        let ranked = candidates.sorted { a, b in
            let urgencyA = (1 - a.masteryLevel) * (predictions[a.id]?.retentionRate ?? 0)
            let urgencyB = (1 - b.masteryLevel) * (predictions[b.id]?.retentionRate ?? 0)
            return urgencyA > urgencyB
        }

        // 生成题目项（题目由 QuestionGenerator 生成，此处生成占位）
        let selected = Array(ranked.prefix(maxItems))
        let items = selected.map { node -> ReviewItem in
            let type: QuestionType
            switch node.category {
            case .fact:     type = .trueFalse
            case .concept:  type = .multipleChoice
            case .procedure: type = .fillInBlank
            case .principle: type = .shortAnswer
            case .skill:    type = .multipleChoice
            }
            return ReviewItem(
                id: UUID(),
                nodeId: node.id,
                questionType: type,
                question: "关于「\(node.title)」的问题（请等待题目生成器生成）",
                options: type == .multipleChoice ? ["A", "B", "C", "D"] : nil,
                correctAnswer: ""
            )
        }

        return ReviewPlan(
            id: UUID(),
            date: now,
            items: items,
            isCompleted: false,
            score: nil,
            totalTarget: selected.count
        )
    }

    // MARK: - 遗忘概率计算
    /// 计算指定时间后的遗忘概率
    public static func forgettingProbability(
        mastery: Double,
        elapsedDays: Double,
        easinessFactor: Double
    ) -> Double {
        // 使用逻辑回归模型近似
        let logit = -3.0 + 2.5 * (1.0 - mastery) + 0.3 * elapsedDays - 1.2 * (easinessFactor - 1.3) / 1.2
        return 1.0 / (1.0 + exp(-logit))
    }
}
