import Foundation
import Combine

final class SimulationViewModel: ObservableObject {
    @Published var accounts: [AccountModel] = []
    @Published var userLowThreshold: Double = 100 // user-defined "low balance" threshold

    // simple dependency: ledger may provide monthly net cashflow estimate
    private var ledger: LedgerViewModel?

    func configure(ledger: LedgerViewModel?) {
        self.ledger = ledger
    }

    /// Load cached accounts from disk and optionally auto-fetch from Nessie if credentials exist.
    func loadCachedAndMaybeRefresh() {
        // Load cached accounts first
        let cached = AccountStore.shared.load()
        if !cached.isEmpty {
            self.accounts = cached
        }

        // If auth exists, try to refresh from server
        if let apiKey = AuthStore.shared.readApiKey(), let customer = AuthStore.shared.readCustomerId() {
            // fetch and persist
            fetchAccountsFromNessie(customerId: customer, apiKey: apiKey) { [weak self] res in
                switch res {
                case .success(let accs):
                    self?.accounts = accs
                    AccountStore.shared.save(accs)
                case .failure:
                    break
                }
            }
        }
    }

    // Accept current accounts (e.g., from PreviewMocks or app data store)
    func load(accounts: [AccountModel]) {
        self.accounts = accounts
    }

    // MARK: - Nessie integration
    /// Fetch accounts from Nessie API and load into the simulator.
    /// - Parameters:
    ///   - customerId: customer identifier in Nessie
    ///   - apiKey: your Nessie API key
    ///   - completion: called on main queue with success/failure
    func fetchAccountsFromNessie(customerId: String, apiKey: String, completion: ((Result<[AccountModel], Error>) -> Void)? = nil) {
        NessieService.shared.fetchAccounts(forCustomerId: customerId, apiKey: apiKey) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let nessieAccounts):
                    // Map NessieAccount -> AccountModel
                    let mapped: [AccountModel] = nessieAccounts.map { na in
                        // choose id: prefer converting _id to UUID if possible, otherwise generate
                        let id: UUID = {
                            if let s = na._id, let u = UUID(uuidString: s) { return u }
                            return UUID()
                        }()

                        // derive type
                        let type: AccountModel.AccountType = {
                            if let t = na.type?.lowercased() {
                                if t.contains("credit") || t.contains("card") { return .creditCard }
                            }
                            return .bank
                        }()

                        let name = na.nickname ?? na.type ?? "Cuenta"
                        let bal = na.balance?.amount ?? 0.0
                        let limit = na.balance?.limit

                        return AccountModel(id: id, name: name, type: type, balance: bal, creditLimit: limit)
                    }
                    self?.accounts = mapped
                    completion?(.success(mapped))
                case .failure(let err):
                    completion?(.failure(err))
                }
            }
        }
    }

    /// Main simulation method. Returns a SimulationResult projecting N months.
    func simulate(purchase: PlannedPurchase, months: Int = 12) -> SimulationResult {
        var alerts: [String] = []

        // estimate monthly net (income - expense). Fallback to 0 if not available.
        let monthlyNet = ledger?.netThisMonth ?? 0

        // Setup initial balances dictionary
        var currentBalances: [UUID: Double] = [:]
        for acc in accounts { currentBalances[acc.id] = acc.balance }

        guard let accountIndex = accounts.firstIndex(where: { $0.id == purchase.accountId }) else {
            return SimulationResult(projected: [], monthlyPayments: [], alerts: ["Cuenta seleccionada no encontrada"], riskIndex: 100)
        }

        let account = accounts[accountIndex]

        // Apply one-time purchase now (month 0)
        if purchase.msiMonths <= 1 {
            // immediate effect: bank balance decreases, credit card balance increases
            if account.type == .bank {
                currentBalances[account.id, default: 0.0] -= purchase.amount
            } else {
                // credit card: increase owed amount (balance stores amount available for bank, for CC we treat balance as owed)
                currentBalances[account.id, default: 0.0] += purchase.amount
            }
        }

        // If credit card and creditLimit exists, check utilization
        if account.type == .creditCard, let limit = account.creditLimit {
            let currentOwed = currentBalances[account.id] ?? 0
            if currentOwed > limit {
                alerts.append("La compra excede el límite de crédito de \(account.name)")
            }
            let util = limit > 0 ? (currentOwed / limit) : 1.0
            if util > 0.95 {
                alerts.append("Utilización de crédito muy alta: \(Int(util * 100))% en \(account.name)")
            }
        } else if account.type == .bank {
            let bal = currentBalances[account.id] ?? 0
            if bal < 0 {
                alerts.append("La compra dejaría la cuenta \(account.name) en saldo negativo: \(String(format: "%.2f", bal))")
            } else if bal < userLowThreshold {
                alerts.append("Saldo bajo en \(account.name): \(String(format: "%.2f", bal))")
            }
        }

        // Build MSI monthly payments schedule if needed
        var monthlyPayments: [MonthlyPayment] = []
        var monthlyMsiAmount: Double = 0
        if purchase.msiMonths > 1 {
            monthlyMsiAmount = purchase.amount / Double(purchase.msiMonths)

            // For credit card MSI we treat it as monthly extra owed (not interest) but with monthly outflow
            var start = Date()
            for m in 0..<purchase.msiMonths {
                let monthStart = Calendar.current.date(byAdding: .month, value: m, to: start) ?? start
                let breakdown: [UUID: Double] = [purchase.accountId: monthlyMsiAmount]
                let mp = MonthlyPayment(monthStart: monthStart, totalPayment: monthlyMsiAmount, breakdown: breakdown)
                monthlyPayments.append(mp)
            }
        }

        // Project forward by month applying monthly net and MSI payments
        var projected: [ProjectedPoint] = []
        let calendar = Calendar.current
        let today = Date()
        for m in 0..<months {
            let monthDate = calendar.date(byAdding: .month, value: m, to: today) ?? today

            // Start with previous balances
            var snapshot = currentBalances

            // Apply monthly net (income - expense) to bank accounts proportionally: for simplicity add to first bank account found
            if monthlyNet != 0 {
                if let bank = accounts.first(where: { $0.type == .bank }) {
                    snapshot[bank.id, default: 0.0] += monthlyNet
                } else {
                    // if no bank account, distribute as negative to credit cards
                    if let cc = accounts.first(where: { $0.type == .creditCard }) {
                        snapshot[cc.id, default: 0.0] -= monthlyNet
                    }
                }
            }

            // Apply MSI payment for this month if present
            if purchase.msiMonths > 1 {
                let mpIndex = monthlyPayments.indices.firstIndex(where: { calendar.isDate(monthlyPayments[$0].monthStart, equalTo: monthDate, toGranularity: .month) })
                // If not exact match, apply by offset: for simplicity assume payments occur each month m from 0..msiMonths-1
                if m < purchase.msiMonths {
                    // subtract monthly payment from the bank account (prefer bank) or increase CC payment
                    if let bank = accounts.first(where: { $0.type == .bank }) {
                        snapshot[bank.id, default: 0.0] -= monthlyMsiAmount
                    } else {
                        snapshot[purchase.accountId, default: 0.0] -= monthlyMsiAmount
                    }
                }
            }

            // For m == 0, if purchase was MSI we didn't subtract the full amount earlier; credit card owed increases only as purchases posted, so for simplicity, when MSI used we consider amount owed on CC increases immediately but payments scheduled reduce liquidity monthly above.
            if m == 0 && purchase.msiMonths > 1 && account.type == .creditCard {
                // ensure owed amount reflects purchase
                snapshot[purchase.accountId, default: 0.0] += 0 // already handled earlier
            }

            // Save snapshot
            projected.append(ProjectedPoint(date: monthDate, balanceByAccount: snapshot))

            // Prepare balances for next month
            currentBalances = snapshot
        }

        // Compute risk index: simple heuristic
        var criticalCount = 0
        for p in projected {
            // if any account below threshold or credit utilization high -> critical
            for acc in accounts {
                let bal = p.balanceByAccount[acc.id] ?? 0
                if acc.type == .bank {
                    if bal < 0 { criticalCount += 2 }
                    else if bal < userLowThreshold { criticalCount += 1 }
                } else if acc.type == .creditCard, let limit = acc.creditLimit {
                    let util = limit > 0 ? ((bal) / limit) : 0
                    if util > 0.95 { criticalCount += 2 }
                    else if util > 0.8 { criticalCount += 1 }
                }
            }
        }

        // Map criticalCount to 0..100
        let maxPossible = max(1, months * accounts.count * 2)
        let raw = Double(criticalCount) / Double(maxPossible)
        let riskIndex = min(100, max(0, Int(raw * 100)))

        // Additional alert: MSI overlap estimate
        if monthlyPayments.count > 0 {
            // compute total MSI monthly burden
            let totalMsiMonthly = monthlyPayments.map { $0.totalPayment }.reduce(0, +) / Double(purchase.msiMonths)
            // if MSI burden exceeds 40% of monthlyNet warn
            if monthlyNet > 0 && totalMsiMonthly > (monthlyNet * 0.4) {
                alerts.append("Los pagos mensuales de MSI podrían representar una carga alta (\(String(format: "%.2f", totalMsiMonthly))/mes)")
            }
        }

        return SimulationResult(projected: projected, monthlyPayments: monthlyPayments, alerts: alerts, riskIndex: riskIndex)
    }
}
