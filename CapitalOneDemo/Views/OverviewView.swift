import SwiftUI
import Combine

struct OverviewScreen: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @EnvironmentObject var monthSelector: MonthSelector
    
    var body: some View {
        VStack(spacing: 16) {
            MonthSelectionControl()
            
            // Saldo total de cuentas checking - CALCULADO DIRECTAMENTE
            Card {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Checking Account Flow (This Month)")
                            .foregroundStyle(Color.white)
                            .font(.caption)
                        Text(String(format: "$%.2f USD", checkingBalanceThisMonth))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(checkingBalanceThisMonth >= 0 ? SwiftFinColor.positiveGreen : SwiftFinColor.negativeRed)
                    }
                }
                .frame(width: 367, height: 50)
            }

            // Total gastado este mes en tarjetas de crédito - CALCULADO DIRECTAMENTE
            Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total spend this month (Credit Cards)")
                        .foregroundStyle(Color.white)
                        .font(.caption)
                    Text(String(format: "$%.2f", creditCardSpentThisMonth))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .frame(width: 367, height: 50)
            }

            Card {
                Text("Cash Flow")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.white)
                BarCashFlow()
                    .frame(height: 180)
            }

            // Recent Transactions - CALCULADAS DIRECTAMENTE
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent Transactions (This Month)")
                            .font(.headline)
                            .foregroundStyle(Color.white)
                        Spacer()
                        Text("\(transactionsThisMonth.count) total")
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    
                    if transactionsThisMonth.isEmpty {
                        Text("No transactions for selected month")
                            .foregroundStyle(Color.white.opacity(0.7))
                            .font(.caption)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(transactionsThisMonth.prefix(5), id: \.id) { tx in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(tx.title)
                                        .foregroundStyle(Color.white)
                                        .font(.caption)
                                    Text(tx.category)
                                        .foregroundStyle(Color.white.opacity(0.7))
                                        .font(.caption2)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(String(format: "$%.2f", tx.amount))
                                        .foregroundStyle(tx.kind == .income ? SwiftFinColor.positiveGreen : SwiftFinColor.negativeRed)
                                        .font(.caption.bold())
                                    Text(DateFormatter.monthDay.string(from: tx.date))
                                        .foregroundStyle(Color.white.opacity(0.5))
                                        .font(.caption2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
            }

            BudgetsSectionConnected()
        }
    }
    
    // MARK: - Computed Properties que se recalculan automáticamente
    
    private var checkingBalanceThisMonth: Double {
        let monthInterval = monthSelector.monthInterval
        let checkingAccounts = ledger.accounts.filter { $0.type.lowercased().contains("checking") }
        let checkingAccountIds = Set(checkingAccounts.map { $0.id })
        
        let incomeInChecking = ledger.transactions.filter {
            $0.kind == .income &&
            monthInterval.contains($0.date) &&
            checkingAccountIds.contains($0.accountId ?? "")
        }.reduce(0) { $0 + $1.amount }
        
        let expensesFromChecking = ledger.transactions.filter {
            $0.kind == .expense &&
            monthInterval.contains($0.date) &&
            checkingAccountIds.contains($0.accountId ?? "")
        }.reduce(0) { $0 + $1.amount }
        
        return incomeInChecking - expensesFromChecking
    }
    
    private var creditCardSpentThisMonth: Double {
        let monthInterval = monthSelector.monthInterval
        
        return ledger.transactions.filter { tx in
            guard tx.kind == .expense && monthInterval.contains(tx.date) else { return false }
            guard let accId = tx.accountId else { return false }
            return ledger.accounts.first(where: { $0.id == accId })?.type.lowercased().contains("credit") ?? false
        }.reduce(0) { $0 + $1.amount }
    }
    
    private var transactionsThisMonth: [Tx] {
        let monthInterval = monthSelector.monthInterval
        return ledger.transactions
            .filter { monthInterval.contains($0.date) }
            .sorted(by: { $0.date > $1.date })
    }
}

// Extensión para formatear fechas
extension DateFormatter {
    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter
    }()
}

// MARK: - Previews
struct OverviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView{
            OverviewScreen()
                .environmentObject(PreviewMocks.ledger)
                .environmentObject(PreviewMocks.monthSelector)
        }
    }
}
