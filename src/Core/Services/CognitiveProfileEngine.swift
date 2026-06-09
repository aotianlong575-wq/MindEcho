import Foundation

/// 认知画像引擎
/// 综合分析用户学习数据，生成多维学习画像
public final class CognitiveProfileEngine {

    // MARK: - 配置
    public struct Config {
        /// 优势/薄弱领域数量
        public var featureCount = 3
        /// 连续学习定义：两天之间的最大间隔（小时）
        public var maxConsecutiveGapHours = 36.0
        /// 历史快照最大保留数
        public var maxHistorySnapshots = 30
    }

    public static var config = Config()

    // MARK: - 画像生成
    /// 根据用户全部知识点和复习记录生成认知画像
    /// - Parameters:
    ///   - nodes: 全部知识点
    ///   - daysSinceFirstActivity: 从第一次学习至今的天数
    /// - Returns: 认知画像
    public static func generateProfile(
        nodes: [KnowledgeNode],
        daysSinceFirstActivity: Int = 7
    ) -> CognitiveProfile {
        guard !nodes.isEmpty else { return emptyProfile() }

        // 总量
        let totalNodes = nodes.count

        // 掌握度统计
        let masteryValues = nodes.map { $0.masteryLevel }
        let avgMastery = masteryValues.reduce(0, +) / Double(totalNodes)

        // 记忆保持率
        let allRetentions = nodes.compactMap { $0.forgettingCurve?.retentionRate }
        let avgRetention = allRetentions.isEmpty ? avgMastery :
            allRetentions.reduce(0, +) / Double(allRetentions.count)

        // 复习完成率
        let reviewedCount = nodes.filter { $0.reviewCount > 0 }.count
        let reviewCompletion = totalNodes > 0 ? Double(reviewedCount) / Double(totalNodes) : 0

        // 知识增长率（本周新增 / 总节点数）
        let weekNewCount = nodes.filter {
            Date().timeIntervalSince($0.createdAt) < 7 * 86400
        }.count
        let weeklyGrowth = Double(weekNewCount) / Double(max(totalNodes, 1))

        // 学习时长估算（每个节点平均 5 分钟 × 复习次数）
        let totalStudyMinutes = nodes.reduce(0.0) { $0 + Double($1.reviewCount) * 5.0 }
        let totalStudyHours = totalStudyMinutes / 60.0

        // 连续学习天数
        let consecutiveDays = calculateConsecutiveDays(nodes)

        // 本周复习次数
        let reviewsThisWeek = nodes.flatMap { $0.reviewHistory }
            .filter { Date().timeIntervalSince($0.date) < 7 * 86400 }
            .count

        // 按分类统计掌握度
        let categoryMastery = masteryByCategory(nodes)

        // 优势/薄弱领域
        let strengths = topCategories(categoryMastery, count: config.featureCount, ascending: false)
        let weaknesses = topCategories(categoryMastery, count: config.featureCount, ascending: true)

        // 学习偏好推断
        let preference = inferLearningPreference(nodes)

        // 历史快照
        let history = buildHistory(nodes, days: min(daysSinceFirstActivity, 30))

        return CognitiveProfile(
            totalStudyHours: round(totalStudyHours * 10) / 10,
            weeklyGrowthRate: round(weeklyGrowth * 100) / 100,
            retentionRate: round(avgRetention * 100) / 100,
            reviewCompletionRate: round(reviewCompletion * 100) / 100,
            overallMastery: round(avgMastery * 100) / 100,
            consecutiveDays: consecutiveDays,
            totalNodes: totalNodes,
            reviewsThisWeek: reviewsThisWeek,
            strengths: strengths,
            weaknesses: weaknesses,
            learningPreference: preference,
            history: history
        )
    }

    /// 生成空画像（新用户）
    public static func emptyProfile() -> CognitiveProfile {
        CognitiveProfile(
            totalStudyHours: 0, weeklyGrowthRate: 0, retentionRate: 0,
            reviewCompletionRate: 0, overallMastery: 0,
            consecutiveDays: 0, totalNodes: 0, reviewsThisWeek: 0,
            strengths: [], weaknesses: [],
            learningPreference: .balanced, history: []
        )
    }

    // MARK: - 分类统计
    /// 按分类计算平均掌握度
    public static func masteryByCategory(_ nodes: [KnowledgeNode]) -> [KnowledgeCategory: Double] {
        var result: [KnowledgeCategory: (sum: Double, count: Int)] = [:]

        for node in nodes {
            let entry = result[node.category, default: (0, 0)]
            result[node.category] = (entry.sum + node.masteryLevel, entry.count + 1)
        }

        return result.mapValues { $0.count > 0 ? $0.sum / Double($0.count) : 0 }
    }

    /// 获取掌握度最高/最低的 N 个分类
    public static func topCategories(_ mastery: [KnowledgeCategory: Double],
                                      count: Int, ascending: Bool) -> [KnowledgeCategory] {
        let sorted = mastery.sorted { ascending ? $0.value < $1.value : $0.value > $1.value }
        return Array(sorted.prefix(count).map { $0.key })
    }

    // MARK: - 趋势分析
    /// 生成学习趋势数据
    public static func buildHistory(_ nodes: [KnowledgeNode], days: Int) -> [ProfileSnapshot] {
        var snapshots: [ProfileSnapshot] = []
        let now = Date()
        // 按天生成快照（最近 N 天）
        // 简化：使用最近一次复习记录作为代表性数据点
        let interval = max(days / config.maxHistorySnapshots, 1)

        for offset in stride(from: days, through: 0, by: -interval) {
            let date = now.addingTimeInterval(-Double(offset) * 86400)
            let pastNodes = nodes.filter { $0.createdAt <= date }

            let total = pastNodes.count
            let avg = total > 0 ? pastNodes.map { $0.masteryLevel }.reduce(0, +) / Double(total) : 0
            let ret = total > 0 ? pastNodes.compactMap { $0.forgettingCurve?.retentionRate }
                .reduce(0, +) / Double(total) : 0
            let reviews = pastNodes.filter { $0.reviewCount > 0 }.count

            snapshots.append(ProfileSnapshot(
                date: date, totalNodes: total,
                averageMastery: round(avg * 100) / 100,
                retentionRate: round(ret * 100) / 100,
                reviewsCompleted: reviews
            ))

            if snapshots.count >= config.maxHistorySnapshots { break }
        }

        return snapshots
    }

    // MARK: - 连续学习计算
    public static func calculateConsecutiveDays(_ nodes: [KnowledgeNode]) -> Int {
        let allDates = nodes.flatMap { node -> [Date] in
            var dates = [node.createdAt]
            dates.append(contentsOf: node.reviewHistory.map { $0.date })
            return dates
        }.sorted()

        guard !allDates.isEmpty else { return 0 }

        let calendar = Calendar.current
        var consecutive = 1
        var maxConsecutive = 1

        for i in 1..<allDates.count {
            let prevDay = calendar.startOfDay(for: allDates[i-1])
            let currDay = calendar.startOfDay(for: allDates[i])
            let diff = currDay.timeIntervalSince(prevDay)

            if diff <= config.maxConsecutiveGapHours * 3600 {
                if diff > 86400 { consecutive += 1 }
                // 同一天不增加
            } else {
                maxConsecutive = max(maxConsecutive, consecutive)
                consecutive = 1
            }
        }
        return max(maxConsecutive, consecutive)
    }

    // MARK: - 学习偏好推断
    public static func inferLearningPreference(_ nodes: [KnowledgeNode]) -> CognitiveProfile.LearningPreference {
        // 如果有 visionOS 交互 → 视觉型
        // 如果有大量文字阅读 → 文本型
        // 如果有大量答题互动 → 互动型
        let totalReviews = nodes.flatMap { $0.reviewHistory }.count
        let avgReviewsPerNode = nodes.isEmpty ? 0 : Double(totalReviews) / Double(nodes.count)

        if avgReviewsPerNode > 5 { return .interactive }
        if nodes.filter({ $0.content.count > 500 }).count > nodes.count / 3 { return .textual }
        if nodes.filter({ $0.tags.count > 5 }).count > nodes.count / 3 { return .visual }

        return .balanced
    }

    // MARK: - 综合评分
    /// 0~100 综合学习评分
    public static func overallScore(for profile: CognitiveProfile) -> Int {
        let score = profile.overallMastery * 40 +
                    profile.retentionRate * 30 +
                    profile.reviewCompletionRate * 20 +
                    min(Double(profile.consecutiveDays) / 14.0 * 10, 10)
        return max(0, min(100, Int(score)))
    }

    /// 生成文字评语
    public static func generateCommentary(for profile: CognitiveProfile) -> String {
        let score = overallScore(for: profile)
        var parts: [String] = []

        switch score {
        case 80...: parts.append("🎉 学习状态非常优秀！继续保持。")
        case 60..<80: parts.append("👍 学习状态良好，仍有提升空间。")
        case 40..<60: parts.append("📚 需要加强复习，知识掌握度偏低。")
        default: parts.append("🚀 刚刚起步，制定好复习计划是关键。")
        }

        if !profile.strengths.isEmpty {
            parts.append("优势领域：\(profile.strengths.map(\.rawValue).joined(separator: "、"))。")
        }
        if !profile.weaknesses.isEmpty {
            parts.append("建议加强：\(profile.weaknesses.map(\.rawValue).joined(separator: "、"))。")
        }

        return parts.joined(separator: " ")
    }
}
