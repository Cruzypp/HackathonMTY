import SwiftUI

struct OverviewScreen: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @EnvironmentObject var monthSelector: MonthSelector
    @StateObject private var vm = OverviewViewModel()

    var body: some View {
        VStack(spacing: 16) {
            MonthSelectionControl()
            
            ChatView()
            
            Card {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Balance").foregroundStyle(SwiftFinColor.textSecondary).font(.caption)
                        Text(String(format: "$%.2f USD", vm.netThisMonth))
                            .font(.system(size: 28, weight: .bold))
                        HStack(spacing: 10) {
                            Button {
                                vm.showAddExpense = true
                            } label: {
                                Label("Add Expense", systemImage: "minus.circle.fill")
                            }
                            .tint(SwiftFinColor.negativeRed)

                            Button {
                                vm.showAddIncome = true
                            } label: {
                                Label("Add Income", systemImage: "plus.circle.fill")
                            }
                            .tint(SwiftFinColor.positiveGreen)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.mini)
                    }
                    Spacer()
                    MiniTrendChart().frame(width: 120, height: 60)
                }
            }

            Card {
                Text("Cash Flow (Jan–Jun)").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                BarCashFlow()
                    .frame(height: 180)
            }

            RecentTransactions(
                title: "Recent Transactions",
                rows: vm.recentRows(),
                onViewAll: { vm.showAllExpenses = true }
            )

            BudgetsSectionConnected()
        }
        // Sheets
        .sheet(isPresented: $vm.showAllExpenses) {
            ViewAllExpensesView().presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $vm.showAddExpense) {
            AddExpenseSheet().presentationDetents([.fraction(0.4)])
        }
        .sheet(isPresented: $vm.showAddIncome) {
            AddIncomeSheet().presentationDetents([.fraction(0.4)])
        }
        .onAppear {
            vm.configure(ledger: ledger, monthSelector: monthSelector)
        }
    }
}

// MARK: - Previews
struct OverviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        OverviewScreen()
            .environmentObject(PreviewMocks.ledger)
            .environmentObject(PreviewMocks.monthSelector)
            .previewDevice("iPhone 14")
            .preferredColorScheme(.dark)
    }
}
