// Expose checking balance for OverviewScreen
import Foundation
import Combine

// Estructura para datos del cash flow que conforme a Identifiable
struct MonthlyCashFlowData: Identifiable {
    let id = UUID()
    let month: String
    let income: Double
    let expense: Double
}

class OverviewViewModel: ObservableObject {
    @Published var checkingBalanceThisMonth: Double = 0
    @Published var creditCardSpentThisMonth: Double = 0
    @Published var recentTransactions: [Tx] = []
    
    @Published var showAllExpenses = false
    @Published var showAddExpense = false
    @Published var showAddIncome = false
    
    private var ledger: LedgerViewModel?
    private var monthSelector: MonthSelector?
    private var cancellables = Set<AnyCancellable>()

    func configure(ledger: LedgerViewModel, monthSelector: MonthSelector) {
        self.ledger = ledger
        self.monthSelector = monthSelector
        
        // Limpiar suscripciones previas
        cancellables.removeAll()
        
        // Suscribirse a cambios en transacciones
        ledger.$transactions
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateData()
                }
            }
            .store(in: &cancellables)
        
        // Crear un timer que verifique cambios en el monthInterval cada segundo
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateData()
            }
            .store(in: &cancellables)
        
        // Forzar actualización inicial
        updateData()
    }
    
    // Método público para forzar actualización cuando cambie el mes
    func refreshData() {
        print("🔄 OverviewViewModel: Manual refresh triggered")
        updateData()
    }

    private func updateData() {
        guard let ledger = ledger, let monthSelector = monthSelector else {
            print("⚠️ OverviewViewModel: Missing dependencies")
            return
        }
        
        let monthInterval = monthSelector.monthInterval
        
        print("🔄 OverviewViewModel: Updating data for month interval: \(monthInterval.start) to \(monthInterval.end)")
        print("📊 OverviewViewModel: Total transactions available: \(ledger.transactions.count)")

        // Filtrar transacciones para el mes seleccionado
        let transactionsForMonth = ledger.transactions.filter { tx in
            monthInterval.contains(tx.date)
        }
        
        print("📊 OverviewViewModel: Transactions for selected month: \(transactionsForMonth.count)")

        // 1. Calcular el saldo de cuentas de cheques para el mes seleccionado
        let checkingAccounts = ledger.accounts.filter { $0.type.lowercased().contains("checking") }
        let checkingAccountIds = Set(checkingAccounts.map { $0.id })
        
        let incomeInChecking = transactionsForMonth.filter {
            $0.kind == .income && checkingAccountIds.contains($0.accountId ?? "")
        }.reduce(0) { $0 + $1.amount }
        
        let expensesFromChecking = transactionsForMonth.filter {
            $0.kind == .expense && checkingAccountIds.contains($0.accountId ?? "")
        }.reduce(0) { $0 + $1.amount }
        
        self.checkingBalanceThisMonth = incomeInChecking - expensesFromChecking
        print("✅ OverviewViewModel: Checking balance for selected month: $\(checkingBalanceThisMonth)")

        // 2. Calcular gastos de tarjetas de crédito para el mes seleccionado
        let creditCardExpenses = transactionsForMonth.filter { tx in
            guard tx.kind == .expense else { return false }
            guard let accId = tx.accountId else { return false }
            return ledger.accounts.first(where: { $0.id == accId })?.type.lowercased().contains("credit") ?? false
        }
        
        self.creditCardSpentThisMonth = creditCardExpenses.reduce(0) { $0 + $1.amount }
        print("✅ OverviewViewModel: Credit card spent for selected month: $\(creditCardSpentThisMonth)")
        print("📊 OverviewViewModel: Found \(creditCardExpenses.count) credit card transactions")

        // 3. Obtener transacciones recientes para el mes seleccionado
        self.recentTransactions = transactionsForMonth
            .sorted(by: { $0.date > $1.date })
        
        print("📋 OverviewViewModel: Found \(recentTransactions.count) transactions for selected month")
    }
    
    func recentRows() -> [TxRowViewModel] {
        recentTransactions.prefix(5).map { tx in
            let account = ledger?.accounts.first(where: { $0.id == tx.accountId })
            return TxRowViewModel(
                id: tx.id.uuidString,
                title: tx.title,
                category: tx.category,
                amount: tx.amount,
                kind: tx.kind,
                date: tx.date,
                accountName: account?.nickname ?? account?.type ?? "N/A"
            )
        }
    }
    
    // Función para generar datos del cash flow mensual
    func monthlyCashFlow(months: Int) -> [MonthlyCashFlowData] {
        guard let ledger = ledger else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        var result: [MonthlyCashFlowData] = []
        
        for i in 0..<months {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            let monthName = monthFormatter.string(from: monthDate)
            
            // Calcular el rango del mes
            let startOfMonth = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
            let endOfMonth = calendar.dateInterval(of: .month, for: monthDate)?.end ?? monthDate
            
            // Calcular income total del mes
            let monthlyIncome = ledger.transactions.filter { tx in
                tx.kind == .income && tx.date >= startOfMonth && tx.date < endOfMonth
            }.reduce(0) { $0 + $1.amount }
            
            // Calcular expense total del mes
            let monthlyExpense = ledger.transactions.filter { tx in
                tx.kind == .expense && tx.date >= startOfMonth && tx.date < endOfMonth
            }.reduce(0) { $0 + $1.amount }
            
            result.append(MonthlyCashFlowData(
                month: monthName,
                income: monthlyIncome,
                expense: monthlyExpense
            ))
        }
        
        return result.reversed()
    }
}

// Estructura temporal para TxRowViewModel si no existe
struct TxRowViewModel {
    let id: String
    let title: String
    let category: String
    let amount: Double
    let kind: Tx.Kind
    let date: Date
    let accountName: String
}
