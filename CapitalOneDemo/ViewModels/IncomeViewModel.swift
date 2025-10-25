import Foundation
import Combine

final class IncomeViewModel: ObservableObject {
    private(set) var ledger: LedgerViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var checkingBalance: Double = 0.0
    @Published var isLoadingBalance: Bool = false

    func configure(ledger: LedgerViewModel, monthSelector: MonthSelector) {
        guard self.ledger == nil else { 
            print("⚠️ IncomeVM: Already configured")
            return 
        }
        self.ledger = ledger
        ledger.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        
        print("🚀 IncomeVM: Configuring and fetching checking balance from API...")
        
        // Fetch checking balance from API
        fetchCheckingBalance()
    }

    var totalIncomeThisMonth: Double { ledger?.totalIncomeThisMonth ?? 0 }
    var incomeThisMonth: [Tx] { ledger?.incomeThisMonth ?? [] }
    
    func refreshData() {
        print("🔄 IncomeVM: Manual refresh triggered")
        fetchCheckingBalance()
    }
    
    func fetchCheckingBalance() {
        // Use stored credentials or fallback to LocalSecrets
        let apiKey = AuthStore.shared.readApiKey() ?? LocalSecrets.nessieApiKey
        let customerId = AuthStore.shared.readCustomerId() ?? LocalSecrets.nessieCustomerId
        
        print("🔍 IncomeVM: Fetching accounts for customer: \(customerId)")
        
        isLoadingBalance = true
        NessieService.shared.fetchAccounts(forCustomerId: customerId, apiKey: apiKey) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingBalance = false
                switch result {
                case .success(let accounts):
                    print("✅ IncomeVM: Got \(accounts.count) accounts")
                    // Find first bank account (checking)
                    if let checking = accounts.first(where: { $0.type.lowercased().contains("checking") || $0.type.lowercased().contains("savings") }) {
                        self?.checkingBalance = checking.balance
                        print("✅ Found checking account with balance: \(checking.balance)")
                    } else if let firstBank = accounts.first {
                        self?.checkingBalance = firstBank.balance
                        print("✅ Using first account with balance: \(firstBank.balance)")
                    }
                case .failure(let error):
                    print("❌ IncomeVM: Error fetching accounts: \(error)")
                }
            }
        }
    }
}
