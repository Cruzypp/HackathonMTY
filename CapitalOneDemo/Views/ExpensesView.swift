import SwiftUI
import Charts

// MARK: - Category Icon Mapping
extension String {
    var categoryIcon: String {
        switch self.lowercased() {
        case "groceries": return "cart.fill"
        case "transport", "transportation": return "car.fill"
        case "bills": return "doc.text.fill"
        case "shopping": return "bag.fill"
        case "dining", "food": return "fork.knife"
        case "healthcare", "health": return "heart.fill"
        case "travel": return "airplane"
        case "entertainment": return "tv.fill"
        case "education": return "book.fill"
        case "other": return "ellipsis.circle.fill"
        default: return "tag.fill"
        }
    }
}

// MARK: - ExpensesScreen Principal
struct ExpensesScreen: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @EnvironmentObject var monthSelector: MonthSelector
    @StateObject private var vm = ExpensesViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                MonthSelectionControl()
            
            // Total credit card debt
            Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Credit Card Debt")
                        .foregroundStyle(SwiftFinColor.textDarkSecondary)
                        .font(.caption)
                    if vm.isLoadingDebt {
                        ProgressView()
                    } else {
                        Text(String(format: "$%.2f", vm.totalCreditDebt))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(SwiftFinColor.negativeRed)
                        
                        if vm.creditCards.count > 0 {
                            Text("\(vm.creditCards.count) card(s)")
                                .font(.caption)
                                .foregroundStyle(SwiftFinColor.textDarkSecondary)
                        }
                    }
                }
            }
            
            Card {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Spent (This Month)")
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                            .font(.caption)
                        Text(String(format: "$%.2f", vm.totalSpentThisMonth))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(SwiftFinColor.textDark)
                    }
                    Spacer()
                }
            }

            Card {
                Text("Spending Distribution")
                    .font(.headline)
                    .foregroundStyle(SwiftFinColor.textDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DonutSpendingConnected()
                    .frame(height: 240)
                    .chartLegend(.hidden)
                LegendSimple(items: vm.spentByCategoryThisMonth())
            }

            Card {
                Text("Spending by Category")
                    .font(.headline)
                    .foregroundStyle(SwiftFinColor.textDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                let categoryData = vm.spentByCategoryThisMonth()
                let totalSpent = categoryData.reduce(0.0) { $0 + $1.amount }
                let palette: [Color] = [.blue, .green, .orange, .purple, .red, .teal, .yellow]
                
                if categoryData.isEmpty {
                    VStack(spacing: 8) {
                        Text("No expenses yet")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                        Text("Start categorizing your purchases to see spending breakdown")
                            .font(.caption2)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(categoryData.enumerated()), id: \.offset) { index, item in
                            CategorySpendingBar(
                                name: item.name,
                                spent: item.amount,
                                total: totalSpent,
                                color: palette[index % palette.count]
                            )
                        }
                    }
                }
            }

            // Credit Card Carousel - Integrado con API
            CreditCardCarouselAPIView(
                creditCards: vm.creditCards,
                isLoadingDebt: vm.isLoadingDebt,
                isLoadingPurchases: vm.isLoadingPurchases,
                purchasesForAccount: vm.purchasesForAccount
            )

            // Checking Accounts Carousel - Only Purchases (categorizable)
            CheckingAccountsPurchasesCarousel(
                accounts: vm.checkingAccounts(),
                isLoadingPurchases: vm.isLoadingPurchases,
                purchasesForAccount: vm.purchasesForAccountUnified
            )

            RecentExpenses()
        }
        .onAppear {
            vm.configure(ledger: ledger, monthSelector: monthSelector)
            // Force a refresh to ensure API purchases (including checking override) are fetched
            vm.refreshData()
        }
        } // Closing NavigationStack
    }
}

// MARK: - Credit Card Carousel integrado con API (Mejorado)
struct CreditCardCarouselAPIView: View {
    @StateObject private var vm = ExpensesViewModel()
    let creditCards: [CreditCardDebt]
    let isLoadingDebt: Bool
    let isLoadingPurchases: Bool
    let purchasesForAccount: (String) -> [PurchaseDisplay]
    
    @State private var currentIndex: Int = 0
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Credit Cards")
                        .font(.headline)
                        .foregroundStyle(SwiftFinColor.textDark)
                    Spacer()
                    
                    // Refresh button
                    Button(action: {
                        vm.refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.accentBlue)
                    }
                    
                    // Botones de navegación manual como fallback
                    if creditCards.count > 1 {
                        HStack(spacing: 12) {
                            Button(action: { previousCard() }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(currentIndex > 0 ? SwiftFinColor.textDark : SwiftFinColor.textDarkSecondary.opacity(0.3))
                            }
                            .disabled(currentIndex <= 0)
                            
                            Text("\(currentIndex + 1) of \(creditCards.count)")
                                .font(.caption)
                                .foregroundStyle(SwiftFinColor.textDarkSecondary)
                            
                            Button(action: { nextCard() }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(currentIndex < creditCards.count - 1 ? SwiftFinColor.textDark : SwiftFinColor.textDarkSecondary.opacity(0.3))
                            }
                            .disabled(currentIndex >= creditCards.count - 1)
                        }
                    }
                    
                    if isLoadingDebt || isLoadingPurchases {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                if !creditCards.isEmpty {
                    SwipeableCardViewWithIndex(
                        items: creditCards,
                        currentIndex: $currentIndex
                    ) { card in
                        CreditCardContent(
                            card: card,
                            purchases: purchasesForAccount(card.id),
                            isLoadingPurchases: isLoadingPurchases
                        )
                    }
                } else if isLoadingDebt {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading credit cards...")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "creditcard")
                            .font(.largeTitle)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                        Text("No credit cards found")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func previousCard() {
        if currentIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex -= 1
            }
        }
    }
    
    private func nextCard() {
        if currentIndex < creditCards.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
        }
    }
}

// MARK: - SwipeableCardView con binding para el índice
struct SwipeableCardViewWithIndex<Item: Identifiable, Content: View>: View {
    let items: [Item]
    @Binding var currentIndex: Int
    let content: (Item) -> Content
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Indicadores de página
            if items.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<items.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? SwiftFinColor.textPrimary : SwiftFinColor.textSecondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .padding(.top, 8)
            }
            
            // Contenido deslizable
            ZStack {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    content(item)
                        .opacity(index == currentIndex ? 1.0 : 0.0)
                        .scaleEffect(index == currentIndex ? 1.0 : 0.95)
                        .offset(x: index == currentIndex ? dragOffset : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentIndex)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: dragOffset)
                }
            }
            .contentShape(Rectangle())
            .clipped()
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                        }
                        dragOffset = value.translation.width * 0.4
                    }
                    .onEnded { value in
                        isDragging = false
                        let threshold: CGFloat = 80
                        let velocity = value.predictedEndTranslation.width
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if (value.translation.width > threshold || velocity > 500) && currentIndex > 0 {
                                currentIndex -= 1
                            } else if (value.translation.width < -threshold || velocity < -500) && currentIndex < items.count - 1 {
                                currentIndex += 1
                            }
                        }
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
            )
            
            // Hint de navegación mejorado
            if items.count > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                        .foregroundStyle(SwiftFinColor.textSecondary.opacity(0.6))
                    Text("Swipe or use buttons to change cards")
                        .font(.caption2)
                        .foregroundStyle(SwiftFinColor.textSecondary.opacity(0.6))
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(SwiftFinColor.textSecondary.opacity(0.6))
                }
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Componente Card Deslizable Genérico (Mejorado)
struct SwipeableCardView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Indicadores de página
            if items.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<items.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? SwiftFinColor.textPrimary : SwiftFinColor.textSecondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .padding(.top, 8)
            }
            
            // Contenido deslizable con mejor gestión de gestos
            ZStack {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    content(item)
                        .opacity(index == currentIndex ? 1.0 : 0.0)
                        .scaleEffect(index == currentIndex ? 1.0 : 0.95)
                        .offset(x: index == currentIndex ? dragOffset : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentIndex)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: dragOffset)
                }
            }
            .contentShape(Rectangle()) // Hace toda el área tappeable/swipeable
            .gesture(
                DragGesture(minimumDistance: 20) // Minimum distance para evitar conflictos
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                        }
                        dragOffset = value.translation.width * 0.5 // Reduce la sensibilidad
                    }
                    .onEnded { value in
                        isDragging = false
                        let threshold: CGFloat = 60 // Aumenta el umbral
                        let velocity = value.predictedEndTranslation.width
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if (value.translation.width > threshold || velocity > 300) && currentIndex > 0 {
                                // Deslizar a la derecha - card anterior
                                currentIndex -= 1
                            } else if (value.translation.width < -threshold || velocity < -300) && currentIndex < items.count - 1 {
                                // Deslizar a la izquierda - siguiente card
                                currentIndex += 1
                            }
                        }
                        
                        // Resetear offset siempre
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
            )
            .allowsHitTesting(true) // Asegura que los gestos funcionen
            
            // Hint de navegación
            if items.count > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                        .foregroundStyle(SwiftFinColor.textSecondary.opacity(0.6))
                    Text("Swipe to change cards")
                        .font(.caption2)
                        .foregroundStyle(SwiftFinColor.textSecondary.opacity(0.6))
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(SwiftFinColor.textSecondary.opacity(0.6))
                }
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Implementación para Credit Cards
struct CreditCardCarouselSimplified: View {
    let creditCards: [CreditCardDebt]
    let purchasesForAccount: (String) -> [PurchaseDisplay]
    
    var body: some View {
        SwipeableCardView(items: creditCards) { card in
            CreditCardContent(
                card: card,
                purchases: purchasesForAccount(card.id), isLoadingPurchases: false
            )
        }
    }
}

// MARK: - Contenido de cada Card
struct CreditCardContent: View {
    let card: CreditCardDebt
    let purchases: [PurchaseDisplay]
    let isLoadingPurchases: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header de la card con alias de la tarjeta
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.accountName) // Este es el alias de la tarjeta (BBVA Oro, Banamex Platinum)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(SwiftFinColor.textDark)
                    Text("Credit Card")
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textDarkSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.2f", card.balance))
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundStyle(SwiftFinColor.negativeRed)
                    Text("Current Balance")
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textDarkSecondary)
                }
            }
            
            Divider()
            
            // Compras recientes de la tarjeta específica
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Purchases")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(SwiftFinColor.textDark)
                    Spacer()
                    if isLoadingPurchases {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("\(purchases.count) total")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                    }
                }
                
                if isLoadingPurchases {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Loading purchases...")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                } else if purchases.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "cart")
                            .font(.title2)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                        Text("No purchases found for this card")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textDarkSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                } else {
                    // Lista con NavigationLinks y badges de categoría
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(purchases.prefix(10)) { purchase in
                                NavigationLink {
                                    PurchaseDetailView(purchase: purchase)
                                } label: {
                                    CreditCardPurchaseRow(purchase: purchase)
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
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
        }
        .padding()
        .background(SwiftFinColor.surface)
        .cornerRadius(12)
        .shadow(color: SwiftFinColor.textSecondary.opacity(0.1), radius: 4)
    }
}

// MARK: - Credit Card Purchase Row (with category icon badge)
struct CreditCardPurchaseRow: View {
    let purchase: PurchaseDisplay
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(SwiftFinColor.surfaceAlt)
                    .frame(width: 36, height: 36)
                Image(systemName: "creditcard.fill")
                    .font(.caption)
                    .foregroundStyle(SwiftFinColor.negativeRed)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(purchase.merchantName)
                    .font(.subheadline)
                    .foregroundStyle(SwiftFinColor.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(purchase.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textSecondary)
                    
                    if let category = purchase.selectedCategory, category != "-" {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textSecondary)
                        
                        Image(systemName: category.categoryIcon)
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.accentBlue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(SwiftFinColor.accentBlue.opacity(0.15))
                            .cornerRadius(4)
                    } else {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textSecondary)
                        Image(systemName: "tag")
                            .font(.caption2)
                            .foregroundStyle(SwiftFinColor.textSecondary)
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
                    .foregroundStyle(SwiftFinColor.textSecondary)
            }
        }
    }
}

// MARK: - Row de Compra
struct PurchaseRow: View {
    let purchase: PurchaseDisplay
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(SwiftFinColor.surfaceAlt)
                    .frame(width: 36, height: 36)
                Image(systemName: "cart.fill")
                    .font(.caption)
                    .foregroundStyle(SwiftFinColor.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(purchase.merchantName)
                    .font(.subheadline)
                    .foregroundStyle(SwiftFinColor.textPrimary)
                    .lineLimit(1)
                Text(purchase.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(SwiftFinColor.textSecondary)
            }
            
            Spacer()
            
            Text(String(format: "−$%.2f", purchase.amount))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(SwiftFinColor.negativeRed)
        }
    }
}

// MARK: - Checking Accounts Purchases Carousel for Expenses
struct CheckingAccountsPurchasesCarousel: View {
    let accounts: [Account]
    let isLoadingPurchases: Bool
    let purchasesForAccount: (String) -> [PurchaseDisplay]
    @State private var currentIndex: Int = 0
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Checking Account Purchases").font(.headline)
                    Spacer()
                    if isLoadingPurchases { ProgressView().scaleEffect(0.8) }
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
                            CheckingAccountPurchasesCard(
                                accountAlias: account.nickname.isEmpty ? account.type : account.nickname,
                                accountId: account.id,
                                purchases: purchasesForAccount(account.id),
                                isLoadingPurchases: isLoadingPurchases
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
                                .foregroundStyle(SwiftFinColor.textSecondary.opacity(0.6))
                            Text("Swipe to change accounts")
                                .font(.caption2)
                                .foregroundStyle(SwiftFinColor.textSecondary.opacity(0.6))
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(SwiftFinColor.textSecondary.opacity(0.6))
                        }
                        .padding(.bottom, 8)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "banknote")
                            .font(.largeTitle)
                            .foregroundStyle(SwiftFinColor.textSecondary)
                        Text("No checking accounts found")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textSecondary)
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Individual Checking Account Purchases Card
struct CheckingAccountPurchasesCard: View {
    let accountAlias: String
    let accountId: String
    let purchases: [PurchaseDisplay]
    let isLoadingPurchases: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(accountAlias)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(SwiftFinColor.textPrimary)
                    Text("Checking Account")
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textSecondary)
                }
                Spacer()
            }
            
            Divider()
            
            // Purchases list
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Purchases")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    if isLoadingPurchases { ProgressView().scaleEffect(0.8) }
                    else {
                        Text("\(purchases.count) total")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textSecondary)
                    }
                }
                
                if isLoadingPurchases {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .frame(height: 150)
                } else {
                    if purchases.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "cart")
                                .font(.title2)
                                .foregroundStyle(SwiftFinColor.textSecondary)
                            Text("No purchases found")
                                .font(.caption)
                                .foregroundStyle(SwiftFinColor.textSecondary)
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
                                        CheckingPurchaseRow(purchase: purchase)
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
        .padding()
        .background(SwiftFinColor.surface)
        .cornerRadius(12)
        .shadow(color: SwiftFinColor.textSecondary.opacity(0.1), radius: 4)
    }
}

// MARK: - Checking Purchase Row (with category icon badge)
struct CheckingPurchaseRow: View {
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
                    .foregroundStyle(SwiftFinColor.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(purchase.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textSecondary)
                    
                    if let category = purchase.selectedCategory, category != "-" {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textSecondary)
                        
                        Image(systemName: category.categoryIcon)
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.accentBlue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(SwiftFinColor.accentBlue.opacity(0.15))
                            .cornerRadius(4)
                    } else {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(SwiftFinColor.textSecondary)
                        Image(systemName: "tag")
                            .font(.caption2)
                            .foregroundStyle(SwiftFinColor.textSecondary)
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
                    .foregroundStyle(SwiftFinColor.textSecondary)
            }
        }
    }
}

// MARK: - Previews
struct ExpensesScreen_Previews: PreviewProvider {
    static var previews: some View {
        
        ExpensesScreen()
            .preferredColorScheme(.dark)
            .environmentObject(PreviewMocks.ledger)
            .environmentObject(PreviewMocks.monthSelector)
            .previewDevice("iPhone 14")
    }
}
