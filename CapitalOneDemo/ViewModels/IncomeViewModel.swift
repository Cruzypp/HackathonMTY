import Foundation
import Combine

// Helper struct for deposits display
struct DepositDisplay: Identifiable {
    let id: String
    let description: String
    let accountAlias: String
    let accountId: String
    let amount: Double
    let date: Date
    let medium: String
}

final class IncomeViewModel: ObservableObject {
    private(set) var ledger: LedgerViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var checkingBalance: Double = 0.0
    @Published var isLoadingBalance: Bool = false
    @Published var apiDeposits: [DepositDisplay] = []
    @Published var apiPurchases: [PurchaseDisplay] = []
    @Published var isLoadingTransactions: Bool = false

    private var lastFetchTime: Date?
    private let cacheDuration: TimeInterval = 180
    
    func configure(ledger: LedgerViewModel, monthSelector: MonthSelector) {
        guard self.ledger == nil else { 
            print("⚠️ IncomeVM: Already configured")
            return 
        }
        self.ledger = ledger
        ledger.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        
        if shouldRefresh() {
            print("🚀 IncomeVM: Configuring and fetching checking data from API...")
            fetchCheckingBalance()
            fetchCheckingTransactions()
        } else {
            print("✅ IncomeVM: Using cached data")
        }
    }
    
    private func shouldRefresh() -> Bool {
        guard let lastTime = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastTime) > cacheDuration
    }
    
    func refreshData() {
        print("🔄 IncomeVM: Manual refresh triggered")
        lastFetchTime = nil
        fetchCheckingBalance()
        fetchCheckingTransactions()
    }
    
    // Get checking accounts for UI
    func checkingAccounts() -> [Account] {
        guard let ledger = ledger else { return [] }
        var list = ledger.accounts.filter { $0.type.lowercased().contains("checking") }
        
        // Always include override checking account if configured
        let overrideId = LocalSecrets.nessieCheckingAccountId
        if !overrideId.isEmpty && !list.contains(where: { $0.id == overrideId }) {
            let synthetic = Account(
                id: overrideId,
                type: "Checking",
                nickname: "BBVA Nómina",
                rewards: 0,
                balance: 0,
                accountNumber: "",
                customerId: LocalSecrets.nessieCustomerId
            )
            list.append(synthetic)
        }
        return list
    }
    
    // Get deposits for a specific account
    func depositsForAccount(_ accountId: String) -> [DepositDisplay] {
        apiDeposits.filter { $0.accountId == accountId }
    }
    
    // Get purchases for a specific account (from checking)
    func purchasesForAccount(_ accountId: String) -> [PurchaseDisplay] {
        apiPurchases.filter { $0.accountId == accountId }
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
    
    func fetchCheckingTransactions() {
        guard !isLoadingTransactions else {
            print("⚠️ IncomeVM: Already loading transactions")
            return
        }
        
        let apiKey = AuthStore.shared.readApiKey() ?? LocalSecrets.nessieApiKey
        let customerId = AuthStore.shared.readCustomerId() ?? LocalSecrets.nessieCustomerId
        
        print("🔍 IncomeVM: Fetching checking transactions for customer: \(customerId)")
        
        isLoadingTransactions = true
        lastFetchTime = Date()
        
        NessieService.shared.fetchAccounts(forCustomerId: customerId, apiKey: apiKey) { [weak self] result in
            switch result {
            case .success(let accounts):
                print("✅ IncomeVM: Got \(accounts.count) accounts for transactions")
                
                // OPTIMIZACIÓN: Usar clase wrapper para estado compartido thread-safe
                let sharedState = TransactionsSharedState()
                let dispatchQueue = DispatchQueue(label: "com.swiftfin.income", attributes: .concurrent)
                let group = DispatchGroup()
                
                let checkingAccounts = accounts.filter { $0.type.lowercased().contains("checking") }
                
                for account in checkingAccounts {
                    group.enter()
                    dispatchQueue.async {
                        self?.processTransactionsForAccount(
                            account,
                            apiKey: apiKey,
                            sharedState: sharedState
                        ) {
                            group.leave()
                        }
                    }
                }
                
                // Override account
                let checkingOverride = LocalSecrets.nessieCheckingAccountId
                if !checkingOverride.isEmpty {
                    group.enter()
                    let account = Account(
                        id: checkingOverride,
                        type: "Checking",
                        nickname: "BBVA Nómina",
                        rewards: 0,
                        balance: 0,
                        accountNumber: "",
                        customerId: customerId
                    )
                    dispatchQueue.async {
                        self?.processTransactionsForAccount(
                            account,
                            apiKey: apiKey,
                            sharedState: sharedState
                        ) {
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    self?.apiDeposits = sharedState.getAllDeposits().sorted { $0.date > $1.date }
                    self?.apiPurchases = sharedState.getAllPurchases().sorted { $0.date > $1.date }
                    self?.isLoadingTransactions = false
                    print("✅ IncomeVM: Total deposits: \(sharedState.getAllDeposits().count), purchases: \(sharedState.getAllPurchases().count)")
                }
                
            case .failure(let error):
                print("❌ IncomeVM: Error fetching accounts: \(error)")
                DispatchQueue.main.async {
                    self?.isLoadingTransactions = false
                }
            }
        }
    }
    
    private func processTransactionsForAccount(
        _ account: Account,
        apiKey: String,
        sharedState: TransactionsSharedState,
        completion: @escaping () -> Void
    ) {
        let accountAlias = account.nickname.isEmpty ? account.type : account.nickname
        let group = DispatchGroup()
        
        // Fetch deposits
        group.enter()
        NessieService.shared.fetchDeposits(forAccountId: account.id, apiKey: apiKey) { result in
            defer { group.leave() }
            if case .success(let deps) = result {
                let displays = deps.map { deposit in
                    DepositDisplay(
                        id: deposit.id,
                        description: deposit.description,
                        accountAlias: accountAlias,
                        accountId: account.id,
                        amount: deposit.amount,
                        date: Self.parseDate(deposit.transaction_date),
                        medium: deposit.medium
                    )
                }
                displays.forEach { sharedState.addDeposit($0) }
            }
        }
        
        // Fetch purchases
        group.enter()
        NessieService.shared.fetchPurchases(forAccountId: account.id, apiKey: apiKey) { result in
            defer { group.leave() }
            if case .success(let purs) = result {
                let displays = purs.map { purchase in
                    PurchaseDisplay(
                        id: purchase.id,
                        merchantName: purchase.description,
                        accountAlias: accountAlias,
                        accountId: account.id,
                        amount: purchase.amount,
                        date: Self.parseDate(purchase.purchaseDate),
                        rawDescription: purchase.description,
                        selectedCategory: CategoryStore.shared.getCategory(for: purchase.id)
                    )
                }
                displays.forEach { sharedState.addPurchase($0) }
            }
        }
        
        group.notify(queue: .global()) {
            completion()
        }
    }
    
    var totalIncomeThisMonth: Double { ledger?.totalIncomeThisMonth ?? 0 }
    var incomeThisMonth: [Tx] { ledger?.incomeThisMonth ?? [] }
    
    // Total expenses this month from ledger
    var totalExpensesThisMonth: Double { ledger?.totalSpentThisMonth ?? 0 }
    var expensesThisMonth: [Tx] { ledger?.expensesThisMonth ?? [] }
    
    // Net = Income - Expenses
    var netThisMonth: Double {
        totalIncomeThisMonth - totalExpensesThisMonth
    }
    
    private static func parseDate(_ s: String) -> Date {
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: s) { return d }
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let d = df.date(from: s) { return d }
        
        let short = DateFormatter()
        short.locale = Locale(identifier: "en_US_POSIX")
        short.dateFormat = "yyyy-MM-dd"
        if let d = short.date(from: s) { return d }
        
        return Date()
    }
}

// MARK: - Thread-Safe Shared State Class
private class TransactionsSharedState {
    private var deposits: [DepositDisplay] = []
    private var purchases: [PurchaseDisplay] = []
    private let lock = NSLock()
    
    func addDeposit(_ deposit: DepositDisplay) {
        lock.lock()
        defer { lock.unlock() }
        deposits.append(deposit)
    }
    
    func addPurchase(_ purchase: PurchaseDisplay) {
        lock.lock()
        defer { lock.unlock() }
        purchases.append(purchase)
    }
    
    func getAllDeposits() -> [DepositDisplay] {
        lock.lock()
        defer { lock.unlock() }
        return deposits
    }
    
    func getAllPurchases() -> [PurchaseDisplay] {
        lock.lock()
        defer { lock.unlock() }
        return purchases
    }
}
