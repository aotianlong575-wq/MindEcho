import SwiftUI
import MindEchoCore

/// 棣栭〉鐪嬫澘
/// 灞曠ず浠婃棩澶嶄範璁″垝銆佸涔犵粺璁°€侀仐蹇橀璀?struct DashboardView: View {
    @State private var todayReviewPlan: ReviewPlan?
    @State private var riskNodes: [KnowledgeNode] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 浠婃棩澶嶄範鍗＄墖
                    TodayReviewCard(plan: todayReviewPlan)

                    // 閬楀繕棰勮鍒楄〃
                    RiskAlertSection(nodes: riskNodes)

                    // 瀛︿範缁熻姒傝
                    StatsOverviewCard()
                }
                .padding()
            }
            .navigationTitle("MindEcho")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { /* 鍚屾 */ }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
            }
        }
    }
}

// MARK: - 瀛愮粍浠?struct TodayReviewCard: View {
    let plan: ReviewPlan?

    var body: some View {
        VStack(alignment: .leading) {
            Label("浠婃棩澶嶄範", systemImage: "calendar.badge.clock")
                .font(.headline)
            if let plan = plan {
                Text("\(plan.items.count) 涓煡璇嗙偣寰呭涔?)
            } else {
                Text("鏆傛棤澶嶄範璁″垝")
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
            Label("閬楀繕棰勮", systemImage: "exclamationmark.triangle.fill")
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
            Label("瀛︿範缁熻", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)

            HStack {
                StatItem(title: "鐭ヨ瘑鐐?, value: "0")
                StatItem(title: "鎺屾彙搴?, value: "0%")
                StatItem(title: "杩炵画瀛︿範", value: "0澶?)
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
