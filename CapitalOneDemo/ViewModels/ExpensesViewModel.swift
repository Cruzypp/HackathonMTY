import Foundation
import Combine

// Helper struct to hold API purchase with merchant info
struct PurchaseDisplay: Identifiable {
    let id: String
    let merchantName: String
    let accountAlias: String
    let accountId: String
    let amount: Double
    let date: Date
}

// Helper for credit card debt summary
struct CreditCardDebt: Identifiable {
    let id: String
    let accountName: String
    let balance: Double
    let limit: Double?
}

final class ExpensesViewModel: ObservableObject {
    private(set) var ledger: LedgerViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var apiPurchases: [PurchaseDisplay] = []
    @Published var isLoadingPurchases: Bool = false
    @Published var creditCards: [CreditCardDebt] = []
    @Published var totalCreditDebt: Double = 0.0
    @Published var isLoadingDebt: Bool = false

    func configure(ledger: LedgerViewModel, monthSelector: MonthSelector) {
        guard self.ledger == nil else { 
            print("⚠️ ExpensesVM: Already configured")
            return 
        }
        self.ledger = ledger
        ledger.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        
        print("🚀 ExpensesVM: Configuring and fetching data from API...")
        
        // Fetch purchases and debt from API
        fetchPurchasesFromAPI()
        fetchCreditCardDebt()
    }

    var totalSpentThisMonth: Double { ledger?.totalSpentThisMonth ?? 0 }
    var budgets: [Budget] { ledger?.budgets ?? [] }
    func spentByCategoryThisMonth() -> [(name: String, amount: Double)] { ledger?.spentByCategoryThisMonth() ?? [] }
    func usedForBudget(_ name: String) -> Double { ledger?.usedForBudget(name) ?? 0 }
    
    func refreshData() {
        print("🔄 ExpensesVM: Manual refresh triggered")
        fetchPurchasesFromAPI()
        fetchCreditCardDebt()
    }
    
    func fetchPurchasesFromAPI() {
        let apiKey = AuthStore.shared.readApiKey() ?? LocalSecrets.nessieApiKey
        let customerId = AuthStore.shared.readCustomerId() ?? LocalSecrets.nessieCustomerId
        
        print("🔍 ExpensesVM: Fetching purchases for customer: \(customerId)")
        
        isLoadingPurchases = true
        
        // First fetch accounts
        NessieService.shared.fetchAccounts(forCustomerId: customerId, apiKey: apiKey) { [weak self] result in
            switch result {
            case .success(let accounts):
                print("✅ ExpensesVM: Got \(accounts.count) accounts")
                var allPurchases: [PurchaseDisplay] = []
                let group = DispatchGroup()
                
                for account in accounts {
                    group.enter()
                    let accountAlias = account.nickname.isEmpty ? account.type : account.nickname
                    
                    print("🔍 Fetching purchases for account: \(accountAlias) (\(account.id))")
                    
                    // Fetch purchases for this account
                    NessieService.shared.fetchPurchases(forAccountId: account.id, apiKey: apiKey) { pResult in
                        defer { group.leave() }
                        
                        switch pResult {
                        case .success(let purchases):
                            print("✅ Got \(purchases.count) purchases for \(accountAlias)")
                            for purchase in purchases {
                                let merchantGroup = DispatchGroup()
                                merchantGroup.enter()
                                
                                var merchantName = purchase.description
                                
                                if !purchase.merchantId.isEmpty {
                                    NessieService.shared.fetchMerchant(forId: purchase.merchantId, apiKey: apiKey) { mResult in
                                        if case .success(let merchant) = mResult {
                                            merchantName = merchant.name
                                        }
                                        merchantGroup.leave()
                                    }
                                    merchantGroup.wait()
                                } else {
                                    merchantGroup.leave()
                                }
                                
                                let date = Self.parseDate(purchase.purchaseDate)
                                let display = PurchaseDisplay(
                                    id: purchase.id,
                                    merchantName: merchantName,
                                    accountAlias: accountAlias,
                                    accountId: account.id,
                                    amount: purchase.amount,
                                    date: date
                                )
                                allPurchases.append(display)
                            }
                        case .failure(let error):
                            print("❌ Error fetching purchases for \(accountAlias): \(error)")
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    self?.apiPurchases = allPurchases.sorted { $0.date > $1.date }
                    self?.isLoadingPurchases = false
                    print("✅ Total purchases loaded: \(allPurchases.count)")
                }
                
            case .failure(let error):
                print("❌ ExpensesVM: Error fetching accounts: \(error)")
                DispatchQueue.main.async {
                    self?.isLoadingPurchases = false
                }
            }
        }
    }
    
    func fetchCreditCardDebt() {
        let apiKey = AuthStore.shared.readApiKey() ?? LocalSecrets.nessieApiKey
        let customerId = AuthStore.shared.readCustomerId() ?? LocalSecrets.nessieCustomerId
        
        isLoadingDebt = true
        
        NessieService.shared.fetchAccounts(forCustomerId: customerId, apiKey: apiKey) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingDebt = false
                switch result {
                case .success(let accounts):
                    // Filter credit card accounts
                    let cards = accounts.filter { 
                        $0.type.lowercased().contains("credit") || $0.type.lowercased().contains("card")
                    }
                    
                    self?.creditCards = cards.map { account in
                        CreditCardDebt(
                            id: account.id,
                            accountName: account.nickname.isEmpty ? account.type : account.nickname,
                            balance: account.balance,
                            limit: nil
                        )
                    }
                    
                    self?.totalCreditDebt = self?.creditCards.reduce(0.0) { $0 + $1.balance } ?? 0.0
                    print("✅ Credit card debt: $\(self?.totalCreditDebt ?? 0)")
                    
                case .failure(let error):
                    print("❌ Error fetching credit debt: \(error)")
                }
            }
        }
    }
    
    // Get purchases for a specific account
    func purchasesForAccount(_ accountId: String) -> [PurchaseDisplay] {
        apiPurchases.filter { $0.accountId == accountId }
    }
    
    private static func parseDate(_ s: String) -> Date {
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: s) { return d }
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let d = df.date(from: s) { return d }
        
        return Date()
    }
}
