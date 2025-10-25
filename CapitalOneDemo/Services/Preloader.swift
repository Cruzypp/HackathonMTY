import Foundation

/// Service responsible for preloading API data into the app's data stores
final class Preloader {
    
    // MARK: - Public Interface
    
    /// Preloads all account and transaction data from Nessie API
    /// - Parameters:
    ///   - customerId: Nessie customer identifier
    ///   - apiKey: Nessie API key
    ///   - ledger: LedgerViewModel to populate with transactions
    static func preloadAll(customerId: String, apiKey: String, into ledger: LedgerViewModel) {
        print("🔄 Preloader: Starting data preload for customer: \(customerId)")
        
        fetchAndStoreAccounts(customerId: customerId, apiKey: apiKey) { accounts in
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
            loadTransactionsForAccounts(allAccounts, apiKey: apiKey, into: ledger)
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
    
    /// Loads transactions (purchases and deposits) for all accounts
    private static func loadTransactionsForAccounts(
        _ accounts: [Account],
        apiKey: String,
        into ledger: LedgerViewModel
    ) {
        for account in accounts {
            let accountAlias = account.nickname.isEmpty ? account.type : account.nickname
            
            loadPurchasesForAccount(account, accountAlias: accountAlias, apiKey: apiKey, into: ledger)
            loadDepositsForAccount(account, accountAlias: accountAlias, apiKey: apiKey, into: ledger)
        }
    }
    
    /// Loads purchases (expenses) for a specific account
    private static func loadPurchasesForAccount(
        _ account: Account,
        accountAlias: String,
        apiKey: String,
        into ledger: LedgerViewModel
    ) {
        NessieService.shared.fetchPurchases(forAccountId: account.id, apiKey: apiKey) { result in
            switch result {
            case .success(let purchases):
                print("📦 Preloader: Processing \(purchases.count) purchases for \(accountAlias)")
                
                for purchase in purchases {
                    processPurchase(purchase, accountAlias: accountAlias, apiKey: apiKey, into: ledger)
                }
                
            case .failure(let error):
                print("❌ Preloader: Failed to fetch purchases for \(accountAlias) - \(error)")
            }
        }
    }
    
    /// Processes a single purchase, fetching merchant info if available
    private static func processPurchase(
        _ purchase: Purchase,
        accountAlias: String,
        apiKey: String,
        into ledger: LedgerViewModel
    ) {
        let date = parseDate(purchase.purchaseDate)
        
        if purchase.merchantId.isEmpty {
            // No merchant ID, use purchase description
            let transaction = Tx(
                date: date,
                title: purchase.description,
                category: "Uncategorized",
                amount: purchase.amount,
                kind: .expense,
                accountId: purchase.payerId,
                purchaseId: purchase.id
            )
            addTransactionToLedger(transaction, ledger: ledger)
        } else {
            // Fetch merchant details
            fetchMerchantAndCreateTransaction(
                purchase: purchase,
                accountAlias: accountAlias,
                apiKey: apiKey,
                into: ledger
            )
        }
    }
    
    /// Fetches merchant details and creates transaction with merchant name
    private static func fetchMerchantAndCreateTransaction(
        purchase: Purchase,
        accountAlias: String,
        apiKey: String,
        into ledger: LedgerViewModel
    ) {
        NessieService.shared.fetchMerchant(forId: purchase.merchantId, apiKey: apiKey) { result in
            let title: String
            switch result {
            case .success(let merchant):
                title = merchant.name
            case .failure:
                title = purchase.description
            }
            
            let transaction = Tx(
                date: parseDate(purchase.purchaseDate),
                title: title,
                category: "Uncategorized",
                amount: purchase.amount,
                kind: .expense,
                accountId: purchase.payerId,
                purchaseId: purchase.id
            )
            addTransactionToLedger(transaction, ledger: ledger)
        }
    }
    
    /// Loads deposits (income) for a specific account
    private static func loadDepositsForAccount(
        _ account: Account,
        accountAlias: String,
        apiKey: String,
        into ledger: LedgerViewModel
    ) {
        NessieService.shared.fetchDeposits(forAccountId: account.id, apiKey: apiKey) { result in
            switch result {
            case .success(let deposits):
                print("💰 Preloader: Processing \(deposits.count) deposits for \(accountAlias)")
                
                let transactions = deposits.map { deposit in
                    Tx(
                        date: parseDate(deposit.transaction_date),
                        title: deposit.description,
                        category: accountAlias,
                        amount: deposit.amount,
                        kind: .income,
                        accountId: deposit.payee_id
                    )
                }
                
                DispatchQueue.main.async {
                    ledger.transactions.append(contentsOf: transactions)
                }
                
            case .failure(let error):
                print("❌ Preloader: Failed to fetch deposits for \(accountAlias) - \(error)")
            }
        }
    }
    
    /// Safely adds a transaction to the ledger on the main queue
    private static func addTransactionToLedger(_ transaction: Tx, ledger: LedgerViewModel) {
        DispatchQueue.main.async {
            print("🧾 Preloader: Upsert Tx -> date=\(transaction.date), title=\(transaction.title), amount=\(transaction.amount), accountId=\(transaction.accountId ?? "nil"), purchaseId=\(transaction.purchaseId ?? "nil")")
            if let pid = transaction.purchaseId,
               let idx = ledger.transactions.firstIndex(where: { $0.purchaseId == pid }) {
                // Update existing transaction (avoid duplicates when reloading)
                ledger.transactions[idx] = transaction
            } else {
                ledger.transactions.append(transaction)
            }
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
