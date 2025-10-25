    // Expose checking balance for OverviewScreen
import Foundation
import Combine

// Helper struct for monthly cash flow data
struct MonthlyCashFlow: Identifiable {
    let id = UUID()
    let month: String
    let monthIndex: Int // 1-12
    let year: Int
    let income: Double
    let expense: Double
    
    var net: Double { income - expense }
}

final class OverviewViewModel: ObservableObject {
    @Published var checkingBalanceThisMonth: Double = 0
    @Published var showAllExpenses = false
    @Published var showAddExpense = false
    @Published var showAddIncome = false

    private(set) var ledger: LedgerViewModel?
    private(set) var monthSelector: MonthSelector?
    private var cancellables = Set<AnyCancellable>()

    func configure(ledger: LedgerViewModel, monthSelector: MonthSelector) {
        guard self.ledger == nil else { return }
        self.ledger = ledger
        self.monthSelector = monthSelector

        ledger.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Fetch real checking account balance from API
        let apiKey = AuthStore.shared.readApiKey() ?? LocalSecrets.nessieApiKey
        let checkingId = "68fcccfb9683f20dd51a43ae" // ID de la cuenta BBVA Nómina
        NessieService.shared.performRequest(
            URLRequest(url: URL(string: "http://api.nessieisreal.com/accounts/\(checkingId)?key=\(apiKey)")!),
            completion: { [weak self] (result: Result<Account, NessieService.NessieError>) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let acc):
                        self?.checkingBalanceThisMonth = acc.balance
                    case .failure:
                        self?.checkingBalanceThisMonth = 0
                    }
                }
            }
        )
    }

    var netThisMonth: Double { ledger?.netThisMonth ?? 0 }
    var expensesThisMonth: [Tx] { ledger?.expensesThisMonth ?? [] }
    var incomeThisMonth: [Tx] { ledger?.incomeThisMonth ?? [] }

    func addExpense(title: String, category: String, amount: Double) { ledger?.addExpense(title: title, category: category, amount: amount) }
    func addIncome(title: String, category: String, amount: Double) { ledger?.addIncome(title: title, category: category, amount: amount) }

    func recentRows() -> [Tx] { Array((expensesThisMonth + incomeThisMonth).sorted { $0.date > $1.date }.prefix(3)) }
    
    // Calculate monthly cash flow for the last N months
    func monthlyCashFlow(months: Int = 10) -> [MonthlyCashFlow] {
        guard let ledger = ledger else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Generate month labels for the last N months
        var monthsData: [MonthlyCashFlow] = []
        
        for i in (0..<months).reversed() {
            guard let targetDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let components = calendar.dateComponents([.year, .month], from: targetDate)
            guard let year = components.year, let month = components.month else { continue }
            
            // Get start and end of this month
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = month
            startComponents.day = 1
            
            guard let startOfMonth = calendar.date(from: startComponents),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                continue
            }
            
            // Filter transactions for this month
            let incomeTransactions = ledger.transactions.filter { tx in
                tx.kind == .income && tx.date >= startOfMonth && tx.date <= endOfMonth
            }
            
            let expenseTransactions = ledger.transactions.filter { tx in
                tx.kind == .expense && tx.date >= startOfMonth && tx.date <= endOfMonth
            }
            
            let totalIncome = incomeTransactions.reduce(0.0) { $0 + $1.amount }
            let totalExpense = expenseTransactions.reduce(0.0) { $0 + $1.amount }
            
            // Month label (short format)
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            let monthLabel = monthFormatter.string(from: targetDate)
            
            monthsData.append(MonthlyCashFlow(
                month: monthLabel,
                monthIndex: month,
                year: year,
                income: totalIncome,
                expense: totalExpense
            ))
        }
        
        return monthsData
    }
}
