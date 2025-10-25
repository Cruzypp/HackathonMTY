import SwiftUI
import Charts

struct MiniTrendChart: View {
    let data = (0..<8).map { i in (x: i, y: Double.random(in: 0.0...1.0)) }
    var body: some View {
        Chart(data, id: \.x) {
            LineMark(x: .value("t", $0.x), y: .value("v", $0.y))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(SwiftFinColor.accentBlue)
            AreaMark(x: .value("t", $0.x), y: .value("v", $0.y))
                .foregroundStyle(SwiftFinColor.accentBlue.opacity(0.25))
        }
        .chartXAxis(.hidden).chartYAxis(.hidden)
    }
}

struct BarCashFlow: View {
    let months = ["Jan","Feb","Mar","Apr","May","Jun"]
    let income = [1800, 2100, 2000, 2300, 2250, 2400]
    let expense = [1200, 1400, 1350, 1500, 1600, 1860]

    var body: some View {
        Chart {
            ForEach(Array(months.enumerated()), id: \.offset) { idx, m in
                BarMark(x: .value("Month", m), y: .value("Income", income[idx]))
                    .foregroundStyle(SwiftFinColor.accentBlue)
                BarMark(x: .value("Month", m), y: .value("Expense", expense[idx]))
                    .foregroundStyle(SwiftFinColor.textSecondary.opacity(0.5))
            }
        }
        .chartYAxisLabel("USD")
        .chartForegroundStyleScale([
            "Income": SwiftFinColor.accentBlue,
            "Expense": SwiftFinColor.textSecondary
        ])
    }
}

struct DonutSpendingConnected: View {
    @EnvironmentObject var ledger: LedgerViewModel
    private let palette: [Color] = [.blue, .green, .orange, .purple, .red, .teal, .yellow]
    var body: some View {
        let data = ledger.spentByCategoryThisMonth()
        let total = max(data.map(\.amount).reduce(0,+), 1)
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { i, row in
                SectorMark(angle: .value("Amount", row.amount), innerRadius: .ratio(0.62))
                    .foregroundStyle(palette[i % palette.count])
                    .annotation(position: .overlay) {
                        let p = row.amount / total
                        if p > 0.10 {
                            Text("\(Int(p * 100))%")
                                .font(.caption2).bold()
                        }
                    }
            }
        }
    }
}

struct BarIncome: View {
    let months = ["May","Jun","Jul","Aug","Sep","Oct"]
    let incomeData = [2000, 2150, 2400, 2200, 2500, 3580.0]

    var body: some View {
        Chart {
            ForEach(Array(months.enumerated()), id: \.offset) { idx, m in
                BarMark(x: .value("Month", m), y: .value("Income", incomeData[idx]))
                    .foregroundStyle(SwiftFinColor.positiveGreen)
            }
        }
        .chartYAxisLabel("USD")
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}
