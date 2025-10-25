import SwiftUI

struct OverviewScreen: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @EnvironmentObject var monthSelector: MonthSelector
    @StateObject private var vm = OverviewViewModel()

    var body: some View {
        VStack(spacing: 16) {
            MonthSelectionControl()
            
            //ChatView()

            // Saldo total de cuentas checking

            Card {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Checking Balance").foregroundStyle(SwiftFinColor.textSecondary).font(.caption)
                        Text(String(format: "$%.2f USD", vm.checkingBalanceThisMonth))
                            .font(.system(size: 28, weight: .bold))
                    }
                }
                .frame(width: 360, height: 50)
            }


            // Total gastado este mes en tarjetas de crédito
            Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total spend this month (Credit Cards)").foregroundStyle(SwiftFinColor.textSecondary).font(.caption)
                    Text(String(format: "$%.2f", totalCreditCardSpentThisMonth))
                        .font(.system(size: 28, weight: .bold))
                }
                .frame(width: 360, height: 50)
            }
            
    // Suma de gastos en tarjetas de crédito en el mes seleccionado
    var totalCreditCardSpentThisMonth: Double {
        let monthInterval = monthSelector.monthInterval
        // Map accountId to account type using ledger.accounts
        return ledger.transactions.filter { tx in
            tx.kind == .expense &&
            monthInterval.contains(tx.date) &&
            {
                guard let accId = tx.accountId else { return false }
                return ledger.accounts.first(where: { $0.id == accId })?.type.lowercased().contains("credit") ?? false
            }()
        }.reduce(0) { $0 + $1.amount }
    }

            Card {
                Text("Cash Flow (Jan–Oct)").font(.headline)
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
