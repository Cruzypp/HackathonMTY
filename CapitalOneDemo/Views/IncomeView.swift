import SwiftUI

struct IncomeScreen: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @EnvironmentObject var monthSelector: MonthSelector
    @StateObject private var vm = IncomeViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                MonthSelectionControl()
            
            Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Income (This Month)")
                        .foregroundStyle(SwiftFinColor.textDarkSecondary)
                        .font(.caption)
                    Text(String(format: "$%.2f", vm.totalIncomeThisMonth))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(SwiftFinColor.textDark)
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(SwiftFinColor.positiveGreen)
                        Text("Monthly trend")
                            .foregroundStyle(SwiftFinColor.positiveGreen)
                            .font(.footnote)
                    }
                }
            }

            // Show checking balance from API
            Card {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Checking Balance (API)")
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                            .font(.caption)
                        Spacer()
                        Button(action: {
                            vm.refreshData()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundStyle(SwiftFinColor.accentBlue)
                        }
                    }
                    if vm.isLoadingBalance {
                        ProgressView()
                    } else {
                        Text(String(format: "$%.2f", vm.checkingBalance))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(SwiftFinColor.textDark)
                    }
                }
            }

            Card {
                Text("Income (last 6 months)")
                    .font(.headline)
                    .foregroundStyle(SwiftFinColor.textDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                BarIncome()
                    .frame(height: 190)
            }

            Card {
                Text("Income Sources (This Month)")
                    .font(.headline)
                    .foregroundStyle(SwiftFinColor.textDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 12) {
                    let total = max(vm.totalIncomeThisMonth, 1)
                    let sources = Dictionary(grouping: vm.incomeThisMonth, by: { $0.category })
                        .map { (name: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
                        .sorted { $0.amount > $1.amount }
                    ForEach(Array(sources.enumerated()), id: \.offset) { _, s in
                        HStack {
                            Label(s.name, systemImage: "creditcard.fill")
                                .foregroundStyle(SwiftFinColor.textDark)
                            Spacer()
                            Text(String(format: "$%.0f", s.amount))
                                .foregroundStyle(SwiftFinColor.textDark)
                        }
                        ProgressView(value: s.amount / total)
                            .tint(SwiftFinColor.accentBlue)
                    }
                }
            }

            Card {
                Text("Expense Sources (This Month)")
                    .font(.headline)
                    .foregroundStyle(SwiftFinColor.textDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 12) {
                    let totalExpenses = max(vm.totalExpensesThisMonth, 1)
                    let expenseSources = Dictionary(grouping: vm.expensesThisMonth, by: { $0.category })
                        .map { (name: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
                        .sorted { $0.amount > $1.amount }
                    
                    if expenseSources.isEmpty {
                        Text("No expenses recorded this month")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(Array(expenseSources.enumerated()), id: \.offset) { _, s in
                            HStack {
                                Label(s.name, systemImage: "cart.fill")
                                    .foregroundStyle(SwiftFinColor.textDark)
                                Spacer()
                                Text(String(format: "$%.0f", s.amount))
                                    .foregroundStyle(SwiftFinColor.negativeRed)
                            }
                            ProgressView(value: s.amount / totalExpenses)
                                .tint(SwiftFinColor.negativeRed)
                        }
                    }
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Net This Month")
                        .foregroundStyle(SwiftFinColor.textDarkSecondary)
                        .font(.caption)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "$%.2f", vm.netThisMonth))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(vm.netThisMonth >= 0 ? SwiftFinColor.positiveGreen : SwiftFinColor.negativeRed)
                        
                        Text(vm.netThisMonth >= 0 ? "(Surplus)" : "(Deficit)")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                    }
                    
                    Divider()
                        .background(SwiftFinColor.textDarkSecondary)
                        .padding(.vertical, 4)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Income")
                                .font(.caption)
                                .foregroundStyle(SwiftFinColor.textDarkSecondary)
                            Text(String(format: "$%.2f", vm.totalIncomeThisMonth))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(SwiftFinColor.positiveGreen)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "minus")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Expenses")
                                .font(.caption)
                                .foregroundStyle(SwiftFinColor.textDarkSecondary)
                            Text(String(format: "$%.2f", vm.totalExpensesThisMonth))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(SwiftFinColor.negativeRed)
                        }
                    }
                }
            }

            // Checking Accounts Carousel with Deposits AND Purchases
            CheckingAccountsCarouselView(
                accounts: vm.checkingAccounts(),
                isLoadingTransactions: vm.isLoadingTransactions,
                depositsForAccount: vm.depositsForAccount,
                purchasesForAccount: vm.purchasesForAccount
            )

            // RecentIncome() - Moved to Checking Accounts Carousel above
        }
        .onAppear { vm.configure(ledger: ledger, monthSelector: monthSelector) }
        } // Close NavigationStack
    }
}

// MARK: - Checking Accounts Carousel for Income
struct CheckingAccountsCarouselView: View {
    let accounts: [Account]
    let isLoadingTransactions: Bool
    let depositsForAccount: (String) -> [DepositDisplay]
    let purchasesForAccount: (String) -> [PurchaseDisplay]
    @State private var currentIndex: Int = 0
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Checking Accounts")
                        .font(.headline)
                        .foregroundStyle(SwiftFinColor.textDark)
                    Spacer()
                    if isLoadingTransactions { ProgressView().scaleEffect(0.8) }
                }
                
                if !accounts.isEmpty {
                    // Page indicators
                    if accounts.count > 1 {
                        HStack(spacing: 8) {
                            ForEach(0..<accounts.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? SwiftFinColor.textPrimary : SwiftFinColor.textSecondary.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // Swipeable cards
                    ZStack {
                        ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                            CheckingAccountCard(
                                accountAlias: account.nickname.isEmpty ? account.type : account.nickname,
                                deposits: depositsForAccount(account.id),
                                purchases: purchasesForAccount(account.id),
                                isLoadingTransactions: isLoadingTransactions
                            )
                            .opacity(index == currentIndex ? 1.0 : 0.0)
                            .scaleEffect(index == currentIndex ? 1.0 : 0.95)
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 30)
                            .onEnded { value in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if value.translation.width > 50 && currentIndex > 0 {
                                        currentIndex -= 1
                                    } else if value.translation.width < -50 && currentIndex < accounts.count - 1 {
                                        currentIndex += 1
                                    }
                                }
                            }
                    )
                    
                    // Navigation hint
                    if accounts.count > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.caption2)
                                .foregroundStyle(SwiftFinColor.textDarkSecondary.opacity(0.6))
                            Text("Swipe to change accounts")
                                .font(.caption2)
                                .foregroundStyle(SwiftFinColor.textDarkSecondary.opacity(0.6))
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(SwiftFinColor.textDarkSecondary.opacity(0.6))
                        }
                        .padding(.bottom, 8)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "banknote")
                            .font(.largeTitle)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                        Text("No checking accounts found")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Individual Checking Account Card
struct CheckingAccountCard: View {
    let accountAlias: String
    let deposits: [DepositDisplay]
    let purchases: [PurchaseDisplay]
    let isLoadingTransactions: Bool
    @State private var selectedTab: TransactionTab = .deposits
    
    enum TransactionTab: String, CaseIterable {
        case deposits = "Deposits"
        case purchases = "Purchases"
    }
    
    var body: some View {
        let _ = print("🎯 CheckingAccountCard: alias=\(accountAlias), deposits=\(deposits.count), purchases=\(purchases.count), loading=\(isLoadingTransactions)")
        
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(accountAlias)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(SwiftFinColor.textDark)
                    Text("Checking Account")
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textDarkSecondary)
                }
                Spacer()
            }
            
            Divider()
            
            // Tab Selector
            Picker("Transaction Type", selection: $selectedTab) {
                ForEach(TransactionTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            
            // Content based on selected tab
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(selectedTab == .deposits ? "Recent Deposits" : "Recent Purchases")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(SwiftFinColor.textDark)
                    Spacer()
                    if isLoadingTransactions { ProgressView().scaleEffect(0.8) }
                    else {
                        let count = selectedTab == .deposits ? deposits.count : purchases.count
                        Text("\(count) total")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                    }
                }
                
                if isLoadingTransactions {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .frame(height: 150)
                } else {
                    if selectedTab == .deposits {
                        if deposits.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.title2)
                                    .foregroundStyle(SwiftFinColor.textDarkSecondary)
                                Text("No deposits found")
                                    .font(.caption)
                                    .foregroundStyle(SwiftFinColor.textDarkSecondary)
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                        } else {
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(deposits.prefix(10)) { deposit in
                                        DepositRow(deposit: deposit)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 8)
                                            .background(SwiftFinColor.surfaceAlt.opacity(0.5))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .frame(maxHeight: 230)
                        }
                    } else {
                        if purchases.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "cart")
                                    .font(.title2)
                                    .foregroundStyle(SwiftFinColor.textDarkSecondary)
                                Text("No purchases found")
                                    .font(.caption)
                                    .foregroundStyle(SwiftFinColor.textDarkSecondary)
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                        } else {
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(purchases.prefix(10)) { purchase in
                                        NavigationLink {
                                            PurchaseDetailView(purchase: purchase)
                                        } label: {
                                            PurchaseRowIncome(purchase: purchase)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .background(SwiftFinColor.surfaceAlt.opacity(0.5))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .frame(maxHeight: 230)
                        }
                    }
                }
            }
        }
        .padding()
        .background(SwiftFinColor.surface)
        .cornerRadius(12)
        .shadow(color: SwiftFinColor.textSecondary.opacity(0.1), radius: 4)
    }
}

// MARK: - Deposit Row
struct DepositRow: View {
    let deposit: DepositDisplay
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(SwiftFinColor.positiveGreen.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "arrow.down.circle.fill")
                    .font(.caption)
                    .foregroundStyle(SwiftFinColor.positiveGreen)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(deposit.description)
                    .font(.subheadline)
                    .foregroundStyle(SwiftFinColor.textDark)
                    .lineLimit(1)
                Text(deposit.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(SwiftFinColor.textDarkSecondary)
            }
            
            Spacer()
            
            Text(String(format: "+$%.2f", deposit.amount))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(SwiftFinColor.positiveGreen)
        }
    }
}

// MARK: - Purchase Row for Income View
struct PurchaseRowIncome: View {
    let purchase: PurchaseDisplay
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(SwiftFinColor.surfaceAlt)
                    .frame(width: 36, height: 36)
                Image(systemName: "cart.fill")
                    .font(.caption)
                    .foregroundStyle(SwiftFinColor.negativeRed)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(purchase.merchantName)
                    .font(.subheadline)
                    .foregroundStyle(SwiftFinColor.textDark)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(purchase.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textDarkSecondary)
                    
                    if let category = purchase.selectedCategory, category != "-" {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                        
                        Image(systemName: category.categoryIcon)
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.accentBlue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(SwiftFinColor.accentBlue.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "−$%.2f", purchase.amount))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(SwiftFinColor.negativeRed)
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(SwiftFinColor.textDarkSecondary)
            }
        }
    }
}

// MARK: - Previews
struct IncomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        IncomeScreen()
            .environmentObject(PreviewMocks.ledger)
            .environmentObject(PreviewMocks.monthSelector)
            .previewDevice("iPhone 14")
            .preferredColorScheme(.dark)
    }
}
