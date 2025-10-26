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
    private(set) var monthSelector: MonthSelector?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var apiPurchases: [PurchaseDisplay] = []
    @Published var isLoadingPurchases: Bool = false
    @Published var creditCards: [CreditCardDebt] = []
    @Published var totalCreditDebt: Double = 0.0
    @Published var isLoadingDebt: Bool = false

    // Cache para evitar recargas
    private var lastFetchTime: Date?
    private let cacheDuration: TimeInterval = 180 // 3 minutos

    func configure(ledger: LedgerViewModel, monthSelector: MonthSelector) {
        guard self.ledger == nil else { 
            print("⚠️ ExpensesVM: Already configured")
            return 
        }
        self.ledger = ledger
        self.monthSelector = monthSelector
        ledger.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        
        // Solo cargar si no hay cache válido
        if shouldRefresh() {
            print("🚀 ExpensesVM: Configuring and fetching data from API...")
            fetchPurchasesFromAPI()
            fetchCreditCardDebt()
        } else {
            print("✅ ExpensesVM: Using cached data")
        }
    }
    
    private func shouldRefresh() -> Bool {
        guard let lastTime = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastTime) > cacheDuration
    }
    
    func refreshData() {
        print("🔄 ExpensesVM: Manual refresh triggered")
        lastFetchTime = nil // Forzar recarga
        fetchPurchasesFromAPI()
        fetchCreditCardDebt()
    }
    
    func fetchPurchasesFromAPI() {
        // Evitar múltiples llamadas simultáneas
        guard !isLoadingPurchases else {
            print("⚠️ ExpensesVM: Already loading purchases")
            return
        }
        
        let apiKey = AuthStore.shared.readApiKey() ?? LocalSecrets.nessieApiKey
        let customerId = AuthStore.shared.readCustomerId() ?? LocalSecrets.nessieCustomerId
        
        print("🔍 ExpensesVM: Fetching purchases for customer: \(customerId)")
        
        isLoadingPurchases = true
        lastFetchTime = Date()
        
        NessieService.shared.fetchAccounts(forCustomerId: customerId, apiKey: apiKey) { [weak self] result in
            switch result {
            case .success(let accounts):
                print("✅ ExpensesVM: Got \(accounts.count) accounts")
                
                // OPTIMIZACIÓN: Usar clase wrapper para estado compartido thread-safe
                let sharedState = PurchasesSharedState()
                let dispatchQueue = DispatchQueue(label: "com.swiftfin.purchases", attributes: .concurrent)
                let group = DispatchGroup()
                
                // Procesar cuentas en paralelo
                for account in accounts {
                    group.enter()
                    dispatchQueue.async {
                        self?.processPurchasesForAccount(
                            account,
                            apiKey: apiKey,
                            sharedState: sharedState
                        ) {
                            group.leave()
                        }
                    }
                }

                // Override checking account
                let checkingOverride = LocalSecrets.nessieCheckingAccountId
                if !checkingOverride.isEmpty {
                    group.enter()
                    dispatchQueue.async {
                        let account = Account(
                            id: checkingOverride,
                            type: "Checking",
                            nickname: "BBVA Nómina",
                            rewards: 0,
                            balance: 0,
                            accountNumber: "",
                            customerId: customerId
                        )
                        self?.processPurchasesForAccount(
                            account,
                            apiKey: apiKey,
                            sharedState: sharedState
                        ) {
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    self?.apiPurchases = sharedState.getAllPurchases().sorted { $0.date > $1.date }
                    self?.isLoadingPurchases = false
                    print("✅ Total purchases loaded: \(sharedState.getAllPurchases().count)")
                }
                
            case .failure(let error):
                print("❌ ExpensesVM: Error fetching accounts: \(error)")
                DispatchQueue.main.async {
                    self?.isLoadingPurchases = false
                }
            }
        }
    }
    
    // Helper para procesar purchases de una cuenta con clase wrapper
    private func processPurchasesForAccount(
        _ account: Account,
        apiKey: String,
        sharedState: PurchasesSharedState,
        completion: @escaping () -> Void
    ) {
        let accountAlias = account.nickname.isEmpty ? account.type : account.nickname
        
        NessieService.shared.fetchPurchases(forAccountId: account.id, apiKey: apiKey) { result in
            defer { completion() }
            
            switch result {
            case .success(let purchases):
                print("✅ Got \(purchases.count) purchases for \(accountAlias)")
                
                for purchase in purchases {
                    // Check if already seen (thread-safe)
                    guard !sharedState.hasSeen(purchaseId: purchase.id) else {
                        continue
                    }
                    
                    sharedState.markAsSeen(purchaseId: purchase.id)
                    
                    let merchantName = purchase.description
                    let date = Self.parseDate(purchase.purchaseDate)
                    let savedCategory = CategoryStore.shared.getCategory(for: purchase.id)
                    
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
                    
                    sharedState.addPurchase(display)
                }
                
            case .failure(let error):
                print("❌ Error fetching purchases for \(accountAlias): \(error)")
            }
        }
    }
    
    var totalSpentThisMonth: Double { ledger?.totalSpentThisMonth ?? 0 }
    var budgets: [Budget] { ledger?.budgets ?? [] }
    
    // MARK: - Purchase Filtering (con filtro de mes)
    
    /// Retorna las compras de una cuenta específica filtradas por el mes seleccionado
    func purchasesForAccount(_ accountId: String) -> [PurchaseDisplay] {
        guard let monthSelector = self.monthSelector else {
            // Fallback: retornar todas las compras sin filtrar
            return apiPurchases.filter { $0.accountId == accountId }.sorted(by: { $0.date > $1.date })
        }
        
        let monthInterval = monthSelector.monthInterval
        
        return apiPurchases
            .filter { purchase in
                purchase.accountId == accountId && monthInterval.contains(purchase.date)
            }
            .sorted(by: { $0.date > $1.date })
    }
    
    /// Versión unificada para checking accounts, también filtrada por mes
    func purchasesForAccountUnified(_ accountId: String) -> [PurchaseDisplay] {
        guard let monthSelector = self.monthSelector else {
            // Fallback: retornar todas las compras sin filtrar
            return apiPurchases.filter { $0.accountId == accountId }.sorted(by: { $0.date > $1.date })
        }
        
        let monthInterval = monthSelector.monthInterval
        
        return apiPurchases
            .filter { purchase in
                purchase.accountId == accountId && monthInterval.contains(purchase.date)
            }
            .sorted(by: { $0.date > $1.date })
    }
    
    /// Retorna gastos agrupados por categoría para el mes seleccionado
    func spentByCategoryThisMonth() -> [(name: String, amount: Double)] {
        guard let ledger = self.ledger, let monthSelector = self.monthSelector else {
            return []
        }
        
        let monthInterval = monthSelector.monthInterval
        
        var dict: [String: Double] = [:]
        
        // Filtrar solo transacciones del mes seleccionado
        ledger.transactions
            .filter { tx in
                tx.kind == .expense && monthInterval.contains(tx.date)
            }
            .forEach { tx in
                let cat = tx.category.isEmpty ? "Other" : tx.category
                dict[cat, default: 0] += tx.amount
            }
        
        return dict.map { (name: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
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

// MARK: - Thread-Safe Shared State Class
private class PurchasesSharedState {
    private var purchases: [PurchaseDisplay] = []
    private var seenIds: Set<String> = []
    private let lock = NSLock()
    
    func hasSeen(purchaseId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return seenIds.contains(purchaseId)
    }
    
    func markAsSeen(purchaseId: String) {
        lock.lock()
        defer { lock.unlock() }
        seenIds.insert(purchaseId)
    }
    
    func addPurchase(_ purchase: PurchaseDisplay) {
        lock.lock()
        defer { lock.unlock() }
        purchases.append(purchase)
    }
    
    func getAllPurchases() -> [PurchaseDisplay] {
        lock.lock()
        defer { lock.unlock() }
        return purchases
    }
}
