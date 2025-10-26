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
    @EnvironmentObject var ledger: LedgerViewModel
    @EnvironmentObject var monthSelector: MonthSelector
    @StateObject private var vm = OverviewViewModel()
    
    var body: some View {
        let monthlyData = vm.monthlyCashFlow(months: 10)
        
        Chart {
            ForEach(monthlyData) { data in
                BarMark(
                    x: .value("Month", data.month),
                    y: .value("Income", data.income)
                )
                .foregroundStyle(SwiftFinColor.positiveGreen)
                .position(by: .value("Type", "Income"))
                
                BarMark(
                    x: .value("Month", data.month),
                    y: .value("Expense", data.expense)
                )
                .foregroundStyle(SwiftFinColor.negativeRed)
                .position(by: .value("Type", "Expense"))
            }
        }
        .chartYAxisLabel("USD")
        .chartForegroundStyleScale([
            "Income": SwiftFinColor.positiveGreen,
            "Expense": SwiftFinColor.negativeRed
        ])
        .chartLegend(position: .bottom, alignment: .center) {
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(SwiftFinColor.positiveGreen)
                        .frame(width: 8, height: 8)
                    Text("Income")
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textSecondary)
                }
                HStack(spacing: 4) {
                    Circle()
                        .fill(SwiftFinColor.negativeRed)
                        .frame(width: 8, height: 8)
                    Text("Expenses")
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textSecondary)
                }
            }
        }
        .onAppear {
            vm.configure(ledger: ledger, monthSelector: monthSelector)
        }
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
    @EnvironmentObject var ledger: LedgerViewModel
    @EnvironmentObject var monthSelector: MonthSelector
    @StateObject private var vm = IncomeViewModel()
    
    // Calculate monthly income data
    private func generateMonthlyData() -> [(month: String, income: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var monthsData: [(month: String, income: Double)] = []
        
        for i in (0..<6).reversed() {
            guard let targetDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let components = calendar.dateComponents([.year, .month], from: targetDate)
            guard let year = components.year, let month = components.month else { continue }
            
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = month
            startComponents.day = 1
            
            guard let startOfMonth = calendar.date(from: startComponents),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                continue
            }
            
            let incomeTransactions = ledger.transactions.filter { tx in
                tx.kind == .income && tx.date >= startOfMonth && tx.date <= endOfMonth
            }
            
            let totalIncome = incomeTransactions.reduce(0.0) { $0 + $1.amount }
            
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            let monthLabel = monthFormatter.string(from: targetDate)
            
            monthsData.append((month: monthLabel, income: totalIncome))
        }
        
        return monthsData
    }
    
    var body: some View {
        let monthsData = generateMonthlyData()
        
        Chart {
            ForEach(Array(monthsData.enumerated()), id: \.offset) { idx, data in
                BarMark(x: .value("Month", data.month), y: .value("Income", data.income))
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
        .onAppear {
            vm.configure(ledger: ledger, monthSelector: monthSelector)
        }
    }
}
