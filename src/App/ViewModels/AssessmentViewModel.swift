import SwiftUI
import MindEchoCore

/// 学习评估 ViewModel
@MainActor
final class AssessmentViewModel: ObservableObject {
    @Published var profile: CognitiveProfile = .init(
        totalStudyHours: 0, weeklyGrowthRate: 0, retentionRate: 0,
        reviewCompletionRate: 0, overallMastery: 0,
        consecutiveDays: 0, totalNodes: 0, reviewsThisWeek: 0,
        strengths: [], weaknesses: [], learningPreference: .balanced, history: []
    )
    @Published var categoryMastery: [KnowledgeCategory: Double] = [:]
    @Published var commentary = ""
    @Published var isLoading = false

    private let engine = CognitiveProfileEngine.self

    func analyze(nodes: [KnowledgeNode]) {
        isLoading = true
        profile = engine.generateProfile(nodes: nodes, daysSinceFirstActivity: 30)
        categoryMastery = engine.masteryByCategory(nodes)
        commentary = engine.generateCommentary(for: profile)
        isLoading = false
    }

    func analyzeSample() {
        analyze(nodes: makeSampleKnowledgeNodes())
    }

    var overallScore: Int { engine.overallScore(for: profile) }

    var categoryRadarData: [(category: KnowledgeCategory, value: Double, maxValue: Double)] {
        KnowledgeCategory.allCases.map { cat in
            (cat, categoryMastery[cat] ?? 0, 1.0)
        }
    }

    // 最大值用于雷达图归一化
    var maxCategoryMastery: Double {
        max(categoryMastery.values.max() ?? 0.5, 0.5)
    }

    var recentSnapshot: ProfileSnapshot? { profile.history.last }

    // 周趋势数据
    var weeklyTrend: [(date: String, mastery: Double, retention: Double)] {
        profile.history.suffix(7).map { snap in
            (snap.date.formatted(.dateTime.month(.twoDigits).day(.twoDigits)),
             snap.averageMastery, snap.retentionRate)
        }
    }
}
