import SwiftUI
import MindEchoCore

/// 学习能力评估 — 雷达图 + 指标 + 趋势 + 评语
struct AssessmentView: View {
    @StateObject private var vm = AssessmentViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 综合评分
                    ScoreGauge(score: vm.overallScore)

                    // 评语
                    CommentaryCard(text: vm.commentary)

                    // 雷达图（能力五维图）
                    RadarChartView(data: vm.categoryRadarData, maxValue: vm.maxCategoryMastery)
                        .frame(height: 240)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // 详细指标
                    MetricsGrid(profile: vm.profile)

                    // 优势/薄弱
                    StrengthsWeaknessesRow(profile: vm.profile)

                    // 趋势图
                    TrendLineView(data: vm.weeklyTrend)
                        .frame(height: 160)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // 历史快照
                    HistorySnapshots(snapshots: vm.profile.history.suffix(5))
                }
                .padding()
            }
            .navigationTitle("学习评估")
            .onAppear { vm.analyzeSample() }
        }
    }
}

// MARK: - 分数仪表盘
struct ScoreGauge: View {
    let score: Int
    var body: some View {
        VStack(spacing: 8) {
            Text("综合学习评分").font(.subheadline).foregroundColor(.secondary)
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(score >= 80 ? Color.green : score >= 60 ? Color.orange : Color.red,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text("\(score)").font(.system(size: 52, weight: .bold))
                    Text("分").font(.caption).foregroundColor(.secondary)
                }
            }
            .frame(width: 150, height: 150)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 评语卡片
struct CommentaryCard: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "quote.bubble.fill").foregroundColor(.blue)
            Text(text).font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 雷达图（五维图）
struct RadarChartView: View {
    let data: [(category: KnowledgeCategory, value: Double, maxValue: Double)]
    let maxValue: Double
    var body: some View {
        VStack(spacing: 8) {
            Text("能力雷达图").font(.headline)
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 20
                let n = data.count
                guard n > 2 else { return }

                // 背景网格
                for level in [0.25, 0.5, 0.75, 1.0] {
                    var gridPath = Path()
                    for (i, _) in data.enumerated() {
                        let angle = -Double.pi / 2 + Double(i) * 2 * Double.pi / Double(n)
                        let x = center.x + CGFloat(cos(angle)) * radius * level
                        let y = center.y + CGFloat(sin(angle)) * radius * level
                        if i == 0 { gridPath.move(to: CGPoint(x: x, y: y)) }
                        else { gridPath.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    gridPath.closeSubpath()
                    ctx.stroke(gridPath, with: .color(.secondary.opacity(0.15)), lineWidth: 1)
                }

                // 轴线
                for (i, _) in data.enumerated() {
                    let angle = -Double.pi / 2 + Double(i) * 2 * Double.pi / Double(n)
                    let end = CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                                      y: center.y + CGFloat(sin(angle)) * radius)
                    var axis = Path(); axis.move(to: center); axis.addLine(to: end)
                    ctx.stroke(axis, with: .color(.secondary.opacity(0.2)))
                }

                // 数据区域
                var dataPath = Path()
                let fillPath = Path()
                for (i, d) in data.enumerated() {
                    let ratio = maxValue > 0 ? d.value / maxValue : 0
                    let angle = -Double.pi / 2 + Double(i) * 2 * Double.pi / Double(n)
                    let x = center.x + CGFloat(cos(angle)) * radius * ratio
                    let y = center.y + CGFloat(sin(angle)) * radius * ratio
                    if i == 0 { dataPath.move(to: CGPoint(x: x, y: y)) }
                    else { dataPath.addLine(to: CGPoint(x: x, y: y)) }
                }
                dataPath.closeSubpath()
                ctx.fill(dataPath, with: .color(.blue.opacity(0.3)))
                ctx.stroke(dataPath, with: .color(.blue), lineWidth: 2)

                // 标签
                for (i, d) in data.enumerated() {
                    let angle = -Double.pi / 2 + Double(i) * 2 * Double.pi / Double(n)
                    let labelPos = CGPoint(x: center.x + CGFloat(cos(angle)) * (radius + 16),
                                           y: center.y + CGFloat(sin(angle)) * (radius + 16))
                    let lbl = ctx.resolve(Text(d.category.rawValue).font(.system(size: 9)))
                    ctx.draw(lbl, at: labelPos)
                }
            }
        }
    }
}

// MARK: - 指标网格
struct MetricsGrid: View {
    let profile: CognitiveProfile
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            MetricCell(title: "知识点", value: "\(profile.totalNodes)", icon: "doc.text", color: .blue)
            MetricCell(title: "掌握度", value: String(format: "%.0f%%", profile.overallMastery * 100),
                       icon: "brain", color: .purple)
            MetricCell(title: "保持率", value: String(format: "%.0f%%", profile.retentionRate * 100),
                       icon: "chart.line.uptrend.xyaxis", color: .green)
            MetricCell(title: "学习时长", value: String(format: "%.1fh", profile.totalStudyHours),
                       icon: "clock", color: .orange)
            MetricCell(title: "连续天数", value: "\(profile.consecutiveDays)天",
                       icon: "flame", color: .red)
            MetricCell(title: "本周复习", value: "\(profile.reviewsThisWeek)次",
                       icon: "repeat", color: .teal)
        }
    }
}

struct MetricCell: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(color).font(.title3)
            Text(value).font(.headline)
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - 优势/薄弱
struct StrengthsWeaknessesRow: View {
    let profile: CognitiveProfile
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("优势领域", systemImage: "hand.thumbsup.fill").font(.subheadline).foregroundColor(.green)
                if profile.strengths.isEmpty {
                    Text("暂无数据").font(.caption).foregroundColor(.secondary)
                } else {
                    ForEach(profile.strengths, id: \.self) { cat in
                        Text(cat.rawValue).font(.caption)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Label("薄弱领域", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline).foregroundColor(.orange)
                if profile.weaknesses.isEmpty {
                    Text("暂无数据").font(.caption).foregroundColor(.secondary)
                } else {
                    ForEach(profile.weaknesses, id: \.self) { cat in
                        Text(cat.rawValue).font(.caption)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - 趋势线
struct TrendLineView: View {
    let data: [(date: String, mastery: Double, retention: Double)]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7日趋势").font(.headline)
            if data.isEmpty {
                Text("暂无趋势数据").foregroundColor(.secondary)
            } else {
                Canvas { ctx, size in
                    guard data.count > 1 else { return }
                    let margin: CGFloat = 30
                    let w = size.width - margin * 2
                    let h = size.height - margin * 2
                    let stepX = w / CGFloat(data.count - 1)

                    // 绘制 mastery 线
                    var masteryPath = Path()
                    var retentionPath = Path()
                    for (i, d) in data.enumerated() {
                        let x = margin + CGFloat(i) * stepX
                        let yM = margin + h * (1 - d.mastery)
                        let yR = margin + h * (1 - d.retention)
                        if i == 0 {
                            masteryPath.move(to: CGPoint(x: x, y: yM))
                            retentionPath.move(to: CGPoint(x: x, y: yR))
                        } else {
                            masteryPath.addLine(to: CGPoint(x: x, y: yM))
                            retentionPath.addLine(to: CGPoint(x: x, y: yR))
                        }
                    }
                    ctx.stroke(masteryPath, with: .color(.blue), style: .init(lineWidth: 2, lineCap: .round))
                    ctx.stroke(retentionPath, with: .color(.green), style: .init(lineWidth: 2, lineCap: .round))

                    // 图例
                    ctx.draw(ctx.resolve(Text("掌握度").font(.system(size: 9)).foregroundColor(.blue)), at: CGPoint(x: margin, y: 10))
                    ctx.draw(ctx.resolve(Text("保持率").font(.system(size: 9)).foregroundColor(.green)), at: CGPoint(x: margin + 50, y: 10))
                }
            }
        }
    }
}

// MARK: - 历史快照
struct HistorySnapshots: View {
    let snapshots: ArraySlice<ProfileSnapshot>
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("学习记录").font(.headline)
            ForEach(Array(snapshots), id: \.date) { snap in
                HStack {
                    Text(snap.date.formatted(date: .numeric, time: .omitted))
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("节点: \(snap.totalNodes)")
                    Text("掌握: \(String(format: "%.0f%%", snap.averageMastery * 100))")
                    Text("复习: \(snap.reviewsCompleted)")
                }
                .font(.caption2)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
