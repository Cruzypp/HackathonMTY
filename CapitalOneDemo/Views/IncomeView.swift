import SwiftUI

struct IncomeScreen: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @EnvironmentObject var monthSelector: MonthSelector
    @StateObject private var vm = IncomeViewModel()
    var body: some View {
        VStack(spacing: 16) {
            MonthSelectionControl()
            
            Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Income (This Month)").foregroundStyle(SwiftFinColor.textSecondary).font(.caption)
                    Text(String(format: "$%.2f", vm.totalIncomeThisMonth))
                        .font(.system(size: 28, weight: .bold))
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right").foregroundStyle(SwiftFinColor.positiveGreen)
                        Text("Monthly trend").foregroundStyle(SwiftFinColor.positiveGreen).font(.footnote)
                    }
                }
            }

            Card {
                Text("Income (last 6 months)").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                BarIncome()
                    .frame(height: 190)
            }

            Card {
                Text("Income Sources (This Month)").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 12) {
                    let total = max(vm.totalIncomeThisMonth, 1)
                    let sources = Dictionary(grouping: vm.incomeThisMonth, by: { $0.category })
                        .map { (name: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
                        .sorted { $0.amount > $1.amount }
                    ForEach(Array(sources.enumerated()), id: \.offset) { _, s in
                        HStack {
                            Label(s.name, systemImage: "creditcard.fill")
                            Spacer()
                            Text(String(format: "$%.0f", s.amount))
                        }
                        ProgressView(value: s.amount / total)
                            .tint(SwiftFinColor.accentBlue)
                    }
                }
            }

            RecentIncome()
        }
        .onAppear { vm.configure(ledger: ledger, monthSelector: monthSelector) }
    }
}

// MARK: - Previews
struct IncomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        IncomeScreen()
            .environmentObject(PreviewMocks.ledger)
            .environmentObject(PreviewMocks.monthSelector)
            .previewDevice("iPhone 14")
            .preferredColorScheme(.dark)
    }
}
