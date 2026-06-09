import Foundation

/// 遗忘预测引擎
/// 结合艾宾浩斯遗忘曲线与 CoreML 模型，
/// 预测用户对知识点的记忆保留率和最佳复习时间
final class ForgettingCurveEngine {
    // MARK: - 艾宾浩斯遗忘曲线
    /// 标准艾宾浩斯公式：R = e^(-t/S) 其中 S 为记忆强度
    /// - Parameter elapsedHours: 距上次复习的小时数
    /// - Parameter strength: 记忆强度参数（由复习次数和难度决定）
    /// - Returns: 预测保留率 (0.0 ~ 1.0)
    static func ebbinghausRetention(elapsedHours: Double, strength: Double) -> Double {
        return exp(-elapsedHours / strength)
    }

    // MARK: - 最佳复习时间计算
    /// 计算下一次最佳复习时间
    /// 基于当前的记忆强度和历史复习记录
    /// - Parameters:
    ///   - node: 知识点
    ///   - strength: 当前记忆强度
    /// - Returns: 最佳复习时间（Date）
    static func calculateOptimalReviewTime(for node: KnowledgeNode, strength: Double) -> Date {
        let retentionThreshold = 0.6  // 当保留率降至 60% 时需要复习
        let hoursUntilReview = -strength * log(retentionThreshold)
        return Date().addingTimeInterval(hoursUntilReview * 3600)
    }

    // MARK: - 风险等级评估
    /// 根据当前掌握度和遗忘速率评估风险等级
    static func assessRisk(mastery: Double, retentionRate: Double) -> ForgettingCurve.RiskLevel {
        switch (mastery, retentionRate) {
        case (let m, _) where m < 0.3:
            return .critical
        case (let m, _) where m < 0.5:
            return .warning
        case (let m, _) where m < 0.7:
            return .moderate
        case (let m, _) where m < 0.9:
            return .good
        default:
            return .excellent
        }
    }

    // MARK: - CoreML 增强预测
    /// 使用机器学习模型增强遗忘预测精度
    /// - Parameter nodes: 用户的知识节点列表
    /// - Returns: 每个节点的遗忘曲线参数
    static func mlEnhancedPrediction(for nodes: [KnowledgeNode]) async -> [UUID: ForgettingCurve] {
        // TODO: 集成 CoreML 模型
        // 1. 加载训练好的遗忘预测模型 (ForgettingPredictor.mlmodel)
        // 2. 构建特征向量：复习次数、难度、时间间隔、历史保留率
        // 3. 批量预测并返回结果
        var predictions: [UUID: ForgettingCurve] = [:]

        for node in nodes {
            let hoursSinceReview = Date().timeIntervalSince(node.lastReviewedAt ?? node.createdAt) / 3600
            let strength = 24.0 * Double(node.reviewCount + 1) * (1.0 + (1.0 - node.difficulty.rawValueAsDouble))
            let retention = ebbinghausRetention(elapsedHours: hoursSinceReview, strength: strength)
            let optimalTime = calculateOptimalReviewTime(for: node, strength: strength)
            let risk = assessRisk(mastery: node.masteryLevel, retentionRate: retention)

            predictions[node.id] = ForgettingCurve(
                nodeId: node.id,
                paramA: strength,
                paramB: 1.0,
                paramC: 0.05,
                predictedForgottenAt: Date().addingTimeInterval(-strength * log(0.3) * 3600),
                retentionRate: retention,
                optimalReviewTime: optimalTime,
                riskLevel: risk
            )
        }

        return predictions
    }
}

// MARK: - DifficultyLevel 扩展
fileprivate extension DifficultyLevel {
    var rawValueAsDouble: Double {
        switch self {
        case .beginner: return 0.2
        case .elementary: return 0.4
        case .intermediate: return 0.6
        case .advanced: return 0.8
        case .expert: return 1.0
        }
    }
}
