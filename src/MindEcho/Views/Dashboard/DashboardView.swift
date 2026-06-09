import SwiftUI

/// 首页看板
/// 展示今日复习计划、学习统计、遗忘预警
struct DashboardView: View {
    @State private var todayReviewPlan: ReviewPlan?
    @State private var riskNodes: [KnowledgeNode] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 今日复习卡片
                    TodayReviewCard(plan: todayReviewPlan)

                    // 遗忘预警列表
                    RiskAlertSection(nodes: riskNodes)

                    // 学习统计概览
                    StatsOverviewCard()
                }
                .padding()
            }
            .navigationTitle("MindEcho")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { /* 同步 */ }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
            }
        }
    }
}

// MARK: - 子组件
struct TodayReviewCard: View {
    let plan: ReviewPlan?

    var body: some View {
        VStack(alignment: .leading) {
            Label("今日复习", systemImage: "calendar.badge.clock")
                .font(.headline)
            if let plan = plan {
                Text("\(plan.items.count) 个知识点待复习")
            } else {
                Text("暂无复习计划")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RiskAlertSection: View {
    let nodes: [KnowledgeNode]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("遗忘预警", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.orange)

            ForEach(nodes.prefix(5)) { node in
                HStack {
                    Circle()
                        .fill(riskColor(node.masteryLevel))
                        .frame(width: 8, height: 8)
                    Text(node.title)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(node.masteryLevel * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func riskColor(_ mastery: Double) -> Color {
        switch mastery {
        case ..<0.3: return .red
        case ..<0.5: return .orange
        case ..<0.7: return .yellow
        default: return .green
        }
    }
}

struct StatsOverviewCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            Label("学习统计", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)

            HStack {
                StatItem(title: "知识点", value: "0")
                StatItem(title: "掌握度", value: "0%")
                StatItem(title: "连续学习", value: "0天")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
