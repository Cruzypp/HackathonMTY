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

    func configure(ledger: LedgerViewModel, monthSelector: MonthSelector) {
        guard self.ledger == nil else { 
            print("⚠️ IncomeVM: Already configured")
            return 
        }
        self.ledger = ledger
        ledger.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        
        print("🚀 IncomeVM: Configuring and fetching checking data from API...")
        
        // Fetch checking balance, deposits, and purchases from API
        fetchCheckingBalance()
        fetchCheckingTransactions()
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
    
    func refreshData() {
        print("🔄 IncomeVM: Manual refresh triggered")
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
        let apiKey = AuthStore.shared.readApiKey() ?? LocalSecrets.nessieApiKey
        let customerId = AuthStore.shared.readCustomerId() ?? LocalSecrets.nessieCustomerId
        
        print("🔍 IncomeVM: Fetching checking transactions for customer: \(customerId)")
        
        isLoadingTransactions = true
        
        NessieService.shared.fetchAccounts(forCustomerId: customerId, apiKey: apiKey) { [weak self] result in
            switch result {
            case .success(let accounts):
                print("✅ IncomeVM: Got \(accounts.count) accounts for transactions")
                var allDeposits: [DepositDisplay] = []
                var allPurchases: [PurchaseDisplay] = []
                let group = DispatchGroup()
                var seenDepositIds = Set<String>()
                var seenPurchaseIds = Set<String>()
                
                // Filter checking accounts
                let checkingAccounts = accounts.filter { $0.type.lowercased().contains("checking") }
                
                for account in checkingAccounts {
                    let accountAlias = account.nickname.isEmpty ? account.type : account.nickname
                    
                    // Fetch deposits
                    group.enter()
                    NessieService.shared.fetchDeposits(forAccountId: account.id, apiKey: apiKey) { dResult in
                        defer { group.leave() }
                        switch dResult {
                        case .success(let deposits):
                            print("✅ IncomeVM: Got \(deposits.count) deposits for \(accountAlias)")
                            for deposit in deposits {
                                guard !seenDepositIds.contains(deposit.id) else { continue }
                                seenDepositIds.insert(deposit.id)
                                let date = Self.parseDate(deposit.transaction_date)
                                let display = DepositDisplay(
                                    id: deposit.id,
                                    description: deposit.description,
                                    accountAlias: accountAlias,
                                    accountId: account.id,
                                    amount: deposit.amount,
                                    date: date,
                                    medium: deposit.medium
                                )
                                allDeposits.append(display)
                            }
                        case .failure(let error):
                            print("❌ IncomeVM: Error fetching deposits for \(accountAlias): \(error)")
                        }
                    }
                    
                    // Fetch purchases
                    group.enter()
                    NessieService.shared.fetchPurchases(forAccountId: account.id, apiKey: apiKey) { pResult in
                        defer { group.leave() }
                        switch pResult {
                        case .success(let purchases):
                            print("✅ IncomeVM: Got \(purchases.count) purchases for \(accountAlias)")
                            for purchase in purchases {
                                guard !seenPurchaseIds.contains(purchase.id) else { continue }
                                seenPurchaseIds.insert(purchase.id)
                                
                                var merchantName = purchase.description
                                if !purchase.merchantId.isEmpty {
                                    let sem = DispatchSemaphore(value: 0)
                                    NessieService.shared.fetchMerchant(forId: purchase.merchantId, apiKey: apiKey) { mResult in
                                        if case .success(let merchant) = mResult {
                                            merchantName = merchant.name
                                        }
                                        sem.signal()
                                    }
                                    sem.wait()
                                }
                                
                                let date = Self.parseDate(purchase.purchaseDate)
                                let display = PurchaseDisplay(
                                    id: purchase.id,
                                    merchantName: merchantName,
                                    accountAlias: accountAlias,
                                    accountId: account.id,
                                    amount: purchase.amount,
                                    date: date,
                                    rawDescription: purchase.description,
                                    selectedCategory: CategoryStore.shared.getCategory(for: purchase.id)
                                )
                                allPurchases.append(display)
                            }
                        case .failure(let error):
                            print("❌ IncomeVM: Error fetching purchases for \(accountAlias): \(error)")
                        }
                    }
                }
                
                // ALWAYS fetch for configured checking account override
                let checkingOverride = LocalSecrets.nessieCheckingAccountId
                if !checkingOverride.isEmpty {
                    let alias = "BBVA Nómina"
                    
                    // Fetch deposits for override
                    group.enter()
                    print("🔍 IncomeVM: EXPLICIT Fetching deposits for checking override: \(checkingOverride)")
                    NessieService.shared.fetchDeposits(forAccountId: checkingOverride, apiKey: apiKey) { dResult in
                        defer { group.leave() }
                        switch dResult {
                        case .success(let deposits):
                            print("✅ IncomeVM: Got \(deposits.count) deposits for checking override")
                            for deposit in deposits {
                                guard !seenDepositIds.contains(deposit.id) else { continue }
                                seenDepositIds.insert(deposit.id)
                                let date = Self.parseDate(deposit.transaction_date)
                                let display = DepositDisplay(
                                    id: deposit.id,
                                    description: deposit.description,
                                    accountAlias: alias,
                                    accountId: checkingOverride,
                                    amount: deposit.amount,
                                    date: date,
                                    medium: deposit.medium
                                )
                                allDeposits.append(display)
                            }
                        case .failure(let error):
                            print("❌ IncomeVM: Error fetching deposits for override: \(error)")
                        }
                    }
                    
                    // Fetch purchases for override
                    group.enter()
                    print("🔍 IncomeVM: EXPLICIT Fetching purchases for checking override: \(checkingOverride)")
                    NessieService.shared.fetchPurchases(forAccountId: checkingOverride, apiKey: apiKey) { pResult in
                        defer { group.leave() }
                        switch pResult {
                        case .success(let purchases):
                            print("✅ IncomeVM: Got \(purchases.count) purchases for checking override")
                            for purchase in purchases {
                                guard !seenPurchaseIds.contains(purchase.id) else { continue }
                                seenPurchaseIds.insert(purchase.id)
                                
                                var merchantName = purchase.description
                                if !purchase.merchantId.isEmpty {
                                    let sem = DispatchSemaphore(value: 0)
                                    NessieService.shared.fetchMerchant(forId: purchase.merchantId, apiKey: apiKey) { mResult in
                                        if case .success(let merchant) = mResult {
                                            merchantName = merchant.name
                                        }
                                        sem.signal()
                                    }
                                    sem.wait()
                                }
                                
                                let date = Self.parseDate(purchase.purchaseDate)
                                let display = PurchaseDisplay(
                                    id: purchase.id,
                                    merchantName: merchantName,
                                    accountAlias: alias,
                                    accountId: checkingOverride,
                                    amount: purchase.amount,
                                    date: date,
                                    rawDescription: purchase.description,
                                    selectedCategory: CategoryStore.shared.getCategory(for: purchase.id)
                                )
                                allPurchases.append(display)
                            }
                        case .failure(let error):
                            print("❌ IncomeVM: Error fetching purchases for override: \(error)")
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    self?.apiDeposits = allDeposits.sorted { $0.date > $1.date }
                    self?.apiPurchases = allPurchases.sorted { $0.date > $1.date }
                    self?.isLoadingTransactions = false
                    print("✅ IncomeVM: Total deposits loaded: \(allDeposits.count)")
                    print("✅ IncomeVM: Total purchases loaded: \(allPurchases.count)")
                }
                
            case .failure(let error):
                print("❌ IncomeVM: Error fetching accounts for transactions: \(error)")
                DispatchQueue.main.async {
                    self?.isLoadingTransactions = false
                }
            }
        }
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
