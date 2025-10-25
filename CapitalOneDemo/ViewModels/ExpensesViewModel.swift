import Foundation
import Combine

// Helper struct to hold API purchase with merchant info and user category
struct PurchaseDisplay: Identifiable {
    let id: String
    let merchantName: String
    let accountAlias: String
    let accountId: String
    let amount: Double
    let date: Date
    let rawDescription: String
    var selectedCategory: String?
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
    
    // Purchases for all checking accounts (using API purchases already fetched)
    func checkingPurchases() -> [PurchaseDisplay] {
        guard let ledger = ledger else { return [] }
        let checkingIds = ledger.accounts
            .filter { $0.type.lowercased().contains("checking") }
            .map { $0.id }
        return apiPurchases
            .filter { checkingIds.contains($0.accountId) }
            .sorted { $0.date > $1.date }
    }

    // Checking accounts list for UI carousels
    func checkingAccounts() -> [Account] {
        guard let ledger = ledger else {
            print("⚠️ checkingAccounts: No ledger available")
            return []
        }
        var list = ledger.accounts.filter { $0.type.lowercased().contains("checking") }
        print("📊 checkingAccounts: Found \(list.count) checking accounts in ledger")
        
        // Always include override checking account if configured, even if it's not in the API accounts list
        let overrideId = LocalSecrets.nessieCheckingAccountId
        print("🔍 checkingAccounts: Override ID configured: \(overrideId)")
        
        if !overrideId.isEmpty && !list.contains(where: { $0.id == overrideId }) {
            print("🔧 ExpensesVM: Adding synthetic checking account for override id: \(overrideId)")
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
        print("📊 checkingAccounts: Returning \(list.count) total checking accounts")
        return list
    }
    
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
                var seenPurchaseIds = Set<String>()
                
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
                                let savedCategory = CategoryStore.shared.getCategory(for: purchase.id)
                                guard !seenPurchaseIds.contains(purchase.id) else { continue }
                                seenPurchaseIds.insert(purchase.id)
                                let display = PurchaseDisplay(
                                    id: purchase.id,
                                    merchantName: merchantName,
                                    accountAlias: accountAlias,
                                    accountId: account.id,
                                    amount: purchase.amount,
                                    date: date,
                                    rawDescription: purchase.description,
                                    selectedCategory: savedCategory
                                )
                                allPurchases.append(display)
                            }
                        case .failure(let error):
                            print("❌ Error fetching purchases for \(accountAlias): \(error)")
                        }
                    }
                }

                // ALWAYS fetch for configured checking account override (even if it's in the list)
                let checkingOverride = LocalSecrets.nessieCheckingAccountId
                print("🏦 Checking override ID from config: '\(checkingOverride)'")
                
                if !checkingOverride.isEmpty {
                    group.enter()
                    let alias = "BBVA Nómina"
                    print("🔍 EXPLICIT Fetching purchases for checking account id: \(checkingOverride)")
                    print("🌐 URL: http://api.nessieisreal.com/accounts/\(checkingOverride)/purchases?key=...")
                    
                    NessieService.shared.fetchPurchases(forAccountId: checkingOverride, apiKey: apiKey) { pResult in
                        defer { group.leave() }
                        switch pResult {
                        case .success(let purchases):
                            print("✅ SUCCESS: Got \(purchases.count) purchases for checking override")
                            for purchase in purchases {
                                var merchantName = purchase.description
                                if !purchase.merchantId.isEmpty {
                                    let sem = DispatchSemaphore(value: 0)
                                    NessieService.shared.fetchMerchant(forId: purchase.merchantId, apiKey: apiKey) { mResult in
                                        if case .success(let merchant) = mResult { merchantName = merchant.name }
                                        sem.signal()
                                    }
                                    sem.wait()
                                }
                                let date = Self.parseDate(purchase.purchaseDate)
                                guard !seenPurchaseIds.contains(purchase.id) else {
                                    print("⚠️ Skipping duplicate purchase: \(purchase.id)")
                                    continue
                                }
                                seenPurchaseIds.insert(purchase.id)
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
                                print("➕ Added purchase: \(merchantName) - $\(purchase.amount)")
                            }
                        case .failure(let error):
                            print("❌ ERROR fetching explicit checking purchases: \(error)")
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

    // Unified purchases for an account: prefer API list; if empty, fallback to ledger transactions
    func purchasesForAccountUnified(_ accountId: String) -> [PurchaseDisplay] {
        print("🔎 purchasesForAccountUnified called for accountId: \(accountId)")
        let api = purchasesForAccount(accountId)
        print("📦 API purchases for \(accountId): \(api.count)")
        
        if !api.isEmpty {
            print("✅ Returning \(api.count) API purchases")
            return api
        }

        print("⚠️ No API purchases, trying ledger fallback...")
        guard let ledger = ledger else {
            print("❌ No ledger available for fallback")
            return []
        }
        
        var alias = ledger.accounts.first(where: { $0.id == accountId })
            .map { $0.nickname.isEmpty ? $0.type : $0.nickname } ?? "Account"
        if accountId == LocalSecrets.nessieCheckingAccountId && alias == "Account" {
            alias = "BBVA Nómina"
        }
        
        let txs = ledger.transactions.filter { $0.kind == .expense && $0.accountId == accountId }
        print("💰 Found \(txs.count) expense transactions in ledger for this account")
        
        let mapped: [PurchaseDisplay] = txs.map { tx in
            let cat = CategoryStore.shared.getCategory(for: tx.purchaseId ?? "")
            return PurchaseDisplay(
                id: tx.purchaseId ?? UUID().uuidString,
                merchantName: tx.title,
                accountAlias: alias,
                accountId: accountId,
                amount: tx.amount,
                date: tx.date,
                rawDescription: tx.title,
                selectedCategory: cat
            )
        }.sorted { $0.date > $1.date }
        
        print("✅ Returning \(mapped.count) mapped purchases from ledger")
        return mapped
    }
    
    private static func parseDate(_ s: String) -> Date {
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: s) { return d }
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let d = df.date(from: s) { return d }
        // Try short date (yyyy-MM-dd)
        let short = DateFormatter()
        short.locale = Locale(identifier: "en_US_POSIX")
        short.dateFormat = "yyyy-MM-dd"
        if let d = short.date(from: s) { return d }

        return Date()
    }
}
