import SwiftUI
import Charts

struct ReportsScreen: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @EnvironmentObject var monthSelector: MonthSelector
    @StateObject private var vm = ReportsViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            MonthSelectionControl()
            
            Card {
                Text("Monthly Summary").font(.title2).frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Income").font(.headline)
                        Text(String(format: "+$%.2f", vm.totalIncomeThisMonth))
                            .font(.title3).bold()
                            .foregroundStyle(SwiftFinColor.positiveGreen)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Expenses").font(.headline)
                        Text(String(format: "-$%.2f", vm.totalSpentThisMonth))
                            .font(.title3).bold()
                            .foregroundStyle(SwiftFinColor.negativeRed)
                    }
                }
                Divider()
                HStack {
                    Text("Net").font(.title3).bold()
                    Spacer()
                    Text(String(format: "%@$%.2f", vm.netThisMonth < 0 ? "−" : "+", abs(vm.netThisMonth)))
                        .font(.title3).bold()
                        .foregroundStyle(vm.netThisMonth < 0 ? SwiftFinColor.negativeRed : SwiftFinColor.positiveGreen)
                }
            }
            
            Card {
                Text("Spending by Category").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DonutSpendingConnected().frame(height: 240).chartLegend(.hidden)
                LegendSimple(items: vm.spentByCategoryThisMonth())
            }
            
            Card {
                Text("Income Distribution").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    let total = max(vm.totalIncomeThisMonth, 1)
                    let sources = Dictionary(grouping: vm.incomeThisMonth, by: { $0.category })
                        .map { (name: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
                        .sorted { $0.amount > $1.amount }
                    
                    if sources.isEmpty {
                        Text("No income recorded this month.")
                            .foregroundStyle(SwiftFinColor.textSecondary)
                    } else {
                        ForEach(Array(sources.enumerated()), id: \.offset) { _, s in
                            HStack {
                                Label(s.name, systemImage: "briefcase.fill")
                                Spacer()
                                Text(String(format: "$%.0f (%.0f%%)", s.amount, (s.amount / total) * 100))
                            }
                            ProgressView(value: s.amount / total)
                                .tint(SwiftFinColor.positiveGreen)
                        }
                    }
                }
            }
        }
        .onAppear { vm.configure(ledger: ledger, monthSelector: monthSelector) }
    }
}

// MARK: - Previews
struct ReportsScreen_Previews: PreviewProvider {
    static var previews: some View {
        ReportsScreen()
            .environmentObject(PreviewMocks.ledger)
            .environmentObject(PreviewMocks.monthSelector)
            .previewDevice("iPhone 14")
            .preferredColorScheme(.dark)
    }
}
