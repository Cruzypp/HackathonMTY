import Foundation

/// Service responsible for preloading API data into the app's data stores
final class Preloader {
    
    // Cache para evitar llamadas duplicadas
    private static var isPreloading = false
    private static var lastPreloadTime: Date?
    private static let cacheTimeout: TimeInterval = 300 // 5 minutos
    
    // MARK: - Public Interface
    
    /// Preloads all account and transaction data from Nessie API
    /// - Parameters:
    ///   - customerId: Nessie customer identifier
    ///   - apiKey: Nessie API key
    ///   - ledger: LedgerViewModel to populate with transactions
    static func preloadAll(customerId: String, apiKey: String, into ledger: LedgerViewModel) {
        // Evitar preload duplicados
        guard !isPreloading else {
            print("⚠️ Preloader: Already preloading, skipping...")
            return
        }
        
        // Cache: no recargar si fue hace menos de 5 minutos
        if let lastTime = lastPreloadTime, Date().timeIntervalSince(lastTime) < cacheTimeout {
            print("✅ Preloader: Using cached data (last load: \(Int(Date().timeIntervalSince(lastTime)))s ago)")
            return
        }
        
        isPreloading = true
        print("🔄 Preloader: Starting optimized data preload for customer: \(customerId)")
        
        fetchAndStoreAccounts(customerId: customerId, apiKey: apiKey) { accounts in
            defer { 
                isPreloading = false
                lastPreloadTime = Date()
            }
            
            var allAccounts = accounts
            
            // Add override checking account if configured and not already in list
            let overrideId = LocalSecrets.nessieCheckingAccountId
            if !overrideId.isEmpty && !allAccounts.contains(where: { $0.id == overrideId }) {
                print("✅ Preloader: Adding override checking account: \(overrideId)")
                let synthetic = Account(
                    id: overrideId,
                    type: "Checking",
                    nickname: "BBVA Nómina",
                    rewards: 0,
                    balance: 0,
                    accountNumber: "",
                    customerId: customerId
                )
                allAccounts.append(synthetic)
            }
            
            guard !allAccounts.isEmpty else {
                print("⚠️ Preloader: No accounts found")
                return
            }
            
            print("✅ Preloader: Stored \(allAccounts.count) accounts")
            // Keep a copy of raw accounts in ledger to map accountId -> account type
            DispatchQueue.main.async {
                ledger.accounts = allAccounts
            }
            
            // OPTIMIZACIÓN: Cargar transacciones en paralelo en lugar de secuencial
            loadTransactionsInParallel(allAccounts, apiKey: apiKey, into: ledger)
        }
    }
    
    // MARK: - Private Methods
    
    /// Fetches accounts from API and stores them locally
    private static func fetchAndStoreAccounts(
        customerId: String,
        apiKey: String,
        completion: @escaping ([Account]) -> Void
    ) {
        NessieService.shared.fetchAccounts(forCustomerId: customerId, apiKey: apiKey) { result in
            switch result {
            case .success(let accounts):
                let accountModels = mapToAccountModels(accounts)
                AccountStore.shared.save(accountModels)
                completion(accounts)
                
            case .failure(let error):
                print("❌ Preloader: Failed to fetch accounts - \(error)")
                completion([])
            }
        }
    }
    
    /// Maps Nessie Account objects to internal AccountModel objects
    private static func mapToAccountModels(_ accounts: [Account]) -> [AccountModel] {
        accounts.map { account in
            let id = UUID(uuidString: account.id) ?? UUID()
            let type: AccountModel.AccountType = account.type.lowercased().contains("credit") ? .creditCard : .bank
            let name = account.nickname.isEmpty ? account.type : account.nickname
            return AccountModel(id: id, name: name, type: type, balance: account.balance, creditLimit: nil)
        }
    }
    
    // NUEVO: Cargar todas las transacciones en paralelo
    private static func loadTransactionsInParallel(
        _ accounts: [Account],
        apiKey: String,
        into ledger: LedgerViewModel
    ) {
        let dispatchGroup = DispatchGroup()
        let transactionsQueue = DispatchQueue(label: "com.swiftfin.transactions", attributes: .concurrent)
        var allTransactions: [Tx] = []
        let transactionsLock = NSLock()
        
        for account in accounts {
            let accountAlias = account.nickname.isEmpty ? account.type : account.nickname
            
            // Cargar purchases en paralelo
            dispatchGroup.enter()
            transactionsQueue.async {
                loadPurchasesSync(account, accountAlias: accountAlias, apiKey: apiKey) { txs in
                    transactionsLock.lock()
                    allTransactions.append(contentsOf: txs)
                    transactionsLock.unlock()
                    dispatchGroup.leave()
                }
            }
            
            // Cargar deposits en paralelo
            dispatchGroup.enter()
            transactionsQueue.async {
                loadDepositsSync(account, accountAlias: accountAlias, apiKey: apiKey) { txs in
                    transactionsLock.lock()
                    allTransactions.append(contentsOf: txs)
                    transactionsLock.unlock()
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("✅ Preloader: All transactions loaded (\(allTransactions.count) total)")
            ledger.transactions.append(contentsOf: allTransactions)
        }
    }
    
    // Versión sincrónica de loadPurchases
    private static func loadPurchasesSync(
        _ account: Account,
        accountAlias: String,
        apiKey: String,
        completion: @escaping ([Tx]) -> Void
    ) {
        let semaphore = DispatchSemaphore(value: 0)
        var transactions: [Tx] = []
        
        NessieService.shared.fetchPurchases(forAccountId: account.id, apiKey: apiKey) { result in
            defer { semaphore.signal() }
            
            switch result {
            case .success(let purchases):
                print("📦 Preloader: Processing \(purchases.count) purchases for \(accountAlias)")
                
                // Procesar en batch para evitar demasiadas llamadas API
                let merchantGroup = DispatchGroup()
                var processedTransactions: [Tx] = []
                
                for purchase in purchases {
                    let date = parseDate(purchase.purchaseDate)
                    
                    if purchase.merchantId.isEmpty {
                        let tx = Tx(
                            date: date,
                            title: purchase.description,
                            category: "Uncategorized",
                            amount: purchase.amount,
                            kind: .expense,
                            accountId: purchase.payerId,
                            purchaseId: purchase.id
                        )
                        processedTransactions.append(tx)
                    } else {
                        merchantGroup.enter()
                        fetchMerchantQuick(purchase.merchantId, apiKey: apiKey) { merchantName in
                            let tx = Tx(
                                date: date,
                                title: merchantName ?? purchase.description,
                                category: "Uncategorized",
                                amount: purchase.amount,
                                kind: .expense,
                                accountId: purchase.payerId,
                                purchaseId: purchase.id
                            )
                            processedTransactions.append(tx)
                            merchantGroup.leave()
                        }
                    }
                }
                
                merchantGroup.wait()
                transactions = processedTransactions
                
            case .failure(let error):
                print("❌ Preloader: Failed to fetch purchases for \(accountAlias) - \(error)")
            }
        }
        
        semaphore.wait()
        completion(transactions)
    }
    
    // Versión sincrónica de loadDeposits
    private static func loadDepositsSync(
        _ account: Account,
        accountAlias: String,
        apiKey: String,
        completion: @escaping ([Tx]) -> Void
    ) {
        let semaphore = DispatchSemaphore(value: 0)
        var transactions: [Tx] = []
        
        NessieService.shared.fetchDeposits(forAccountId: account.id, apiKey: apiKey) { result in
            defer { semaphore.signal() }
            
            switch result {
            case .success(let deposits):
                print("💰 Preloader: Processing \(deposits.count) deposits for \(accountAlias)")
                
                transactions = deposits.map { deposit in
                    Tx(
                        date: parseDate(deposit.transaction_date),
                        title: deposit.description,
                        category: accountAlias,
                        amount: deposit.amount,
                        kind: .income,
                        accountId: deposit.payee_id
                    )
                }
                
            case .failure(let error):
                print("❌ Preloader: Failed to fetch deposits for \(accountAlias) - \(error)")
            }
        }
        
        semaphore.wait()
        completion(transactions)
    }
    
    // Cache de merchants para evitar llamadas duplicadas
    private static var merchantCache: [String: String] = [:]
    private static let merchantCacheLock = NSLock()
    
    private static func fetchMerchantQuick(_ merchantId: String, apiKey: String, completion: @escaping (String?) -> Void) {
        merchantCacheLock.lock()
        if let cached = merchantCache[merchantId] {
            merchantCacheLock.unlock()
            completion(cached)
            return
        }
        merchantCacheLock.unlock()
        
        NessieService.shared.fetchMerchant(forId: merchantId, apiKey: apiKey) { result in
            let name: String? = {
                switch result {
                case .success(let merchant):
                    return merchant.name
                case .failure:
                    return nil
                }
            }()
            
            if let name = name {
                merchantCacheLock.lock()
                merchantCache[merchantId] = name
                merchantCacheLock.unlock()
            }
            
            completion(name)
        }
    }
    
    /// Parses date string from API into Date object
    private static func parseDate(_ dateString: String) -> Date {
        // Try ISO8601 format first
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        // Try full date-time format
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }

        // Try just date (yyyy-MM-dd)
        let shortFormatter = DateFormatter()
        shortFormatter.locale = Locale(identifier: "en_US_POSIX")
        shortFormatter.dateFormat = "yyyy-MM-dd"
        if let date = shortFormatter.date(from: dateString) {
            return date
        }

        // Fallback to current date
        print("⚠️ Preloader: Unable to parse date '\(dateString)', using current date")
        return Date()
    }
}
