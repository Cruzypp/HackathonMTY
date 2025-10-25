import SwiftUI
import Charts

struct ExpensesScreen: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @EnvironmentObject var monthSelector: MonthSelector
    @StateObject private var vm = ExpensesViewModel()

    var body: some View {
        VStack(spacing: 16) {
            MonthSelectionControl()
            
            Card {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Spent (This Month)").foregroundStyle(SwiftFinColor.textSecondary).font(.caption)
                        Text(String(format: "$%.2f", vm.totalSpentThisMonth))
                            .font(.system(size: 28, weight: .bold))
                    }
                    Spacer()
                }
            }

            Card {
                Text("Spending Distribution").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DonutSpendingConnected()
                    .frame(height: 240)
                    .chartLegend(.hidden)
                LegendSimple(items: vm.spentByCategoryThisMonth())
            }

            Card {
                Text("Spending by Category").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 12) {
                    ForEach(vm.budgets) { b in
                        let used = vm.usedForBudget(b.name)
                        CategoryRowBar(name: b.name, spent: used, budget: b.total)
                    }
                }
            }

            RecentExpenses()
        }
        .onAppear { vm.configure(ledger: ledger, monthSelector: monthSelector) }
    }
}

// MARK: - Previews
struct ExpensesScreen_Previews: PreviewProvider {
    static var previews: some View {
        ExpensesScreen()
            .preferredColorScheme(.dark)
            .environmentObject(PreviewMocks.ledger)
            .environmentObject(PreviewMocks.monthSelector)
            .previewDevice("iPhone 14")
    }
}
