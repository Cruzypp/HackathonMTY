    // Expose checking balance for OverviewScreen
import Foundation
import Combine

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
}
