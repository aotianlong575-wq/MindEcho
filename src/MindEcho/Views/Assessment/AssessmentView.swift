import SwiftUI

/// 学习能力评估
/// 展示学习画像：时长、增长率、保持率、完成率、掌握度
struct AssessmentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 综合评分
                    OverallScoreCard(score: 75)

                    // 雷达图区域
                    RadarChartPlaceholder()

                    // 详细指标
                    MetricsDetailSection()

                    // 优势与薄弱
                    StrengthsWeaknessesSection()

                    // 历史趋势
                    TrendChartPlaceholder()
                }
                .padding()
            }
            .navigationTitle("学习评估")
        }
    }
}

struct OverallScoreCard: View {
    let score: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("综合学习评分")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold))
            }
            .frame(width: 140, height: 140)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RadarChartPlaceholder: View {
    var body: some View {
        VStack {
            Text("能力雷达图")
                .font(.headline)
            // TODO: 使用 Swift Charts 绘制雷达图
            RoundedRectangle(cornerRadius: 8)
                .fill(.secondary.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("雷达图区域")
                        .foregroundColor(.secondary)
                )
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MetricsDetailSection: View {
    let metrics: [(String, String, String)] = [
        ("学习时长", "0 小时", "clock.fill"),
        ("知识增长率", "0 / 周", "chart.line.uptrend.xyaxis"),
        ("记忆保持率", "0%", "brain.head.profile"),
        ("复习完成率", "0%", "checklist"),
        ("知识掌握度", "0%", "star.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细指标")
                .font(.headline)

            ForEach(metrics, id: \.0) { (title, value, icon) in
                HStack {
                    Image(systemName: icon)
                        .frame(width: 24)
                        .foregroundColor(.blue)
                    Text(title)
                    Spacer()
                    Text(value)
                        .fontWeight(.semibold)
                }
                Divider()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StrengthsWeaknessesSection: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Label("优势领域", systemImage: "hand.thumbsup.fill")
                    .foregroundColor(.green)
                    .font(.headline)
                Text("暂无数据")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading) {
                Label("薄弱领域", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.headline)
                Text("暂无数据")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct TrendChartPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("历史趋势")
                .font(.headline)
            // TODO: 使用 Swift Charts 绘制趋势图
            RoundedRectangle(cornerRadius: 8)
                .fill(.secondary.opacity(0.1))
                .frame(height: 180)
                .overlay(
                    Text("趋势图表区域")
                        .foregroundColor(.secondary)
                )
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
