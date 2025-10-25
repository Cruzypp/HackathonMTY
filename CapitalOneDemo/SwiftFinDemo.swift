//
//  SwiftFinApp_FullCode.swift
//  SwiftFin – Dark UI starter with Store, Screens, Sheets & Reports
//  Requires iOS 16+ (Charts)
//
//  
//

import SwiftUI
import Charts
import Combine

// MARK: - Color helpers (no necesitas crear nada extra)
extension Color {
    /// Hex like "#0B1220" or "0B1220"
    init(hex: String, alpha: Double = 1.0) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b).opacity(alpha)
    }
}

/// Design tokens (paleta fría modo oscuro)
enum SwiftFinColor {
    static let bgPrimary       = Color(hex: "#0B1220")      // fondo principal
    static let surface         = Color(hex: "#0F172A")      // tarjetas
    static let surfaceAlt      = Color(hex: "#111827")
    static let textPrimary     = Color(hex: "#E5E7EB")
    static let textSecondary   = Color(hex: "#94A3B8")
    static let accentBlue      = Color(hex: "#3B82F6")
    static let positiveGreen   = Color(hex: "#22C55E")
    static let negativeRed     = Color(hex: "#EF4444")
    static let divider         = Color(hex: "#1F2937")
}

// MARK: - Month Selector Store
final class MonthSelector: ObservableObject {
    @Published var selectedDate: Date = Date()
    
    var currentMonthYear: String {
        selectedDate.formatted(.dateTime.month().year())
    }
    
    var monthInterval: DateInterval {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year,.month], from: selectedDate))!
        let end = cal.date(byAdding: .month, value: 1, to: start)!
        return DateInterval(start: start, end: end)
    }
    
    func nextMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate)!
    }
    
    func previousMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate)!
    }
    
    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .month)
    }
}

// MARK: - Ledger Store
final class LedgerStore: ObservableObject {
    
    // Injected dependency
    @ObservedObject var monthSelector: MonthSelector
    
    // Listener for Combine
    private var cancellables = Set<AnyCancellable>()
    
    struct Tx: Identifiable {
        enum Kind { case expense, income }
        let id = UUID()
        var date: Date
        var title: String
        var category: String
        var amount: Double    // valor absoluto
        var kind: Kind
    }

    struct Budget: Identifiable {
        let id = UUID()
        var name: String
        var total: Double
    }

    // Published Data
    @Published var transactions: [Tx] = [
        .init(date: .now, title: "Groceries", category: "Food", amount: 48.2, kind: .expense),
        .init(date: .now, title: "Metro", category: "Transport", amount: 12, kind: .expense),
        .init(date: .now.addingTimeInterval(TimeInterval(-86400*3)), title: "Salary", category: "Salary", amount: 3200, kind: .income),
        .init(date: .now.addingTimeInterval(TimeInterval(-86400*10)), title: "Upwork", category: "Freelance", amount: 380, kind: .income),
        .init(date: .now.addingTimeInterval(TimeInterval(-86400*5)), title: "Electric Bill", category: "Bills", amount: 450, kind: .expense),
        .init(date: .now.addingTimeInterval(TimeInterval(-86400*6)), title: "Dinner", category: "Food", amount: 420, kind: .expense),
    ]

    @Published var budgets: [Budget] = [
        .init(name: "Rent", total: 900),
        .init(name: "Entertainment", total: 600),
        .init(name: "Groceries", total: 700)
    ]
    
    // Initializer to receive the dependency
    init(monthSelector: MonthSelector) {
        self.monthSelector = monthSelector
        
        // Configurar un listener para forzar la actualización de LedgerStore
        monthSelector.$selectedDate
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // El mesInterval ahora usa la propiedad inyectada
    private var selectedMonthInterval: DateInterval { monthSelector.monthInterval }
    
    // Filtros
    var expensesThisMonth: [Tx] {
        transactions.filter { $0.kind == .expense && selectedMonthInterval.contains($0.date) }
    }
    var incomeThisMonth: [Tx] {
        transactions.filter { $0.kind == .income && selectedMonthInterval.contains($0.date) }
    }

    // Totales
    var totalSpentThisMonth: Double { expensesThisMonth.reduce(0) { $0 + $1.amount } }
    var totalIncomeThisMonth: Double { incomeThisMonth.reduce(0) { $0 + $1.amount } }
    var netThisMonth: Double { totalIncomeThisMonth - totalSpentThisMonth }

    // Agregar datos
    func addExpense(title: String, category: String, amount: Double, date: Date = .now) {
        transactions.append(.init(date: date, title: title, category: category, amount: amount, kind: .expense))
    }
    func addIncome(title: String, category: String, amount: Double, date: Date = .now) {
        transactions.append(.init(date: date, title: title, category: category, amount: amount, kind: .income))
    }
    func addBudget(name: String, total: Double) {
        budgets.append(.init(name: name, total: total))
    }

    // Desgloses
    func spentByCategoryThisMonth() -> [(name: String, amount: Double)] {
        let grouped = Dictionary(grouping: expensesThisMonth, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return grouped.map { ($0.key, $0.value) }.sorted { $0.amount > $1.amount }
    }
    func usedForBudget(_ name: String) -> Double {
        expensesThisMonth.filter { $0.category == name || ($0.category == "Food" && name == "Groceries") }
            .reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Demo App (SOLUCIÓN DEFINITIVA AL ERROR DE INICIALIZACIÓN)
@main
struct SwiftFinDemoApp: App {
    
    // 1. Declara las propiedades, pero NO las inicialices en la declaración.
    @StateObject var monthSelector: MonthSelector
    @StateObject var ledger: LedgerStore
    
    // 2. Usa el init() para controlar el orden
    init() {
        // 3. Crea la instancia de la dependencia (MonthSelector) PRIMERO y guárdala localmente.
        let ms = MonthSelector()
        
        // 4. Asigna esa instancia local (ms) a la propiedad envuelta (wrappedValue) de monthSelector.
        _monthSelector = StateObject(wrappedValue: ms)
        
        // 5. INYECTA la misma instancia (ms) en el LedgerStore al inicializarlo.
        _ledger = StateObject(wrappedValue: LedgerStore(monthSelector: ms))
    }
    
    var body: some Scene {
        WindowGroup {
            SwiftFinRoot()
                .environmentObject(ledger)
                .environmentObject(monthSelector) // Inyectar ambos al entorno
                .preferredColorScheme(.dark)
        }
    }
}
// MARK: - Root with Header + Segmented
enum TopTab: String, CaseIterable { case overview = "Overview", expenses = "Expenses", income = "Income", reports = "Reports" }

struct SwiftFinRoot: View {
    @EnvironmentObject var ledger: LedgerStore
    @State private var topTab: TopTab = .overview

    var body: some View {
        ZStack {
            SwiftFinColor.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Header()
                TopSegmentedControl(selection: $topTab)

                // Content card
                ScrollView {
                    VStack(spacing: 16) {
                        switch topTab {
                        case .overview: OverviewScreen()
                        case .expenses: ExpensesScreen()
                        case .income:   IncomeScreen()
                        case .reports:  ReportsScreen()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .foregroundStyle(SwiftFinColor.textPrimary)
    }
}

// MARK: - Header
struct Header: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bird.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(SwiftFinColor.accentBlue)
            Text("SwiftFin")
                .font(.system(size: 22, weight: .semibold))
            Spacer()
            Circle()
                .fill(SwiftFinColor.surfaceAlt)
                .frame(width: 28, height: 28)
                .overlay(Image(systemName: "person.fill").font(.footnote))
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
        .background(SwiftFinColor.bgPrimary.opacity(0.95))
    }
}

// MARK: - Top Segmented
struct TopSegmentedControl: View {
    @Binding var selection: TopTab
    var body: some View {
        HStack(spacing: 8) {
            ForEach(TopTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selection == tab ? .white : SwiftFinColor.textSecondary)
                        .padding(.vertical, 8).padding(.horizontal, 12)
                        .background(selection == tab ? SwiftFinColor.accentBlue : SwiftFinColor.surfaceAlt)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }
}

// MARK: - Month Selection Control
struct MonthSelectionControl: View {
    @EnvironmentObject var monthSelector: MonthSelector
    
    var body: some View {
        HStack {
            Button {
                monthSelector.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Spacer()
            
            Label(monthSelector.currentMonthYear, systemImage: "calendar")
                .font(.subheadline).bold()
                .padding(.vertical, 8).padding(.horizontal, 12)
                .background(SwiftFinColor.surfaceAlt).clipShape(Capsule())
            
            Spacer()

            Button {
                monthSelector.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .disabled(monthSelector.isCurrentMonth)
        }
        .foregroundStyle(SwiftFinColor.textPrimary)
        .padding(.horizontal, 16)
    }
}


// MARK: - Reusable Card
struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .background(SwiftFinColor.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(SwiftFinColor.divider, lineWidth: 1))
    }
}

// MARK: - Overview Screen
struct OverviewScreen: View {
    @EnvironmentObject var ledger: LedgerStore
    @State private var showAllExpenses = false
    @State private var showAddIncome = false
    @State private var showAddExpense = false

    var body: some View {
        VStack(spacing: 16) {
            MonthSelectionControl()
            
            Card {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Balance").foregroundStyle(SwiftFinColor.textSecondary).font(.caption)
                        Text(String(format: "$%.2f USD", ledger.netThisMonth))
                            .font(.system(size: 28, weight: .bold))
                        HStack(spacing: 10) {
                            Button {
                                showAddExpense = true
                            } label: {
                                Label("Add Expense", systemImage: "minus.circle.fill")
                            }
                            .tint(SwiftFinColor.negativeRed)

                            Button {
                                showAddIncome = true
                            } label: {
                                Label("Add Income", systemImage: "plus.circle.fill")
                            }
                            .tint(SwiftFinColor.positiveGreen)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.mini)
                    }
                    Spacer()
                    MiniTrendChart().frame(width: 120, height: 60)
                }
            }

            Card {
                Text("Cash Flow (Jan–Jun)").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                BarCashFlow()
                    .frame(height: 180)
            }

            RecentTransactions(
                title: "Recent Transactions",
                rows: Array((ledger.expensesThisMonth + ledger.incomeThisMonth).sorted(by: { $0.date > $1.date }).prefix(3)),
                onViewAll: { showAllExpenses = true }
            )

            BudgetsSectionConnected()
        }
        // Sheets
        .sheet(isPresented: $showAllExpenses) {
            ViewAllExpensesView().presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseSheet().presentationDetents([.fraction(0.4)])
        }
        .sheet(isPresented: $showAddIncome) {
            AddIncomeSheet().presentationDetents([.fraction(0.4)])
        }
    }
}

// MARK: - Expenses Screen
struct ExpensesScreen: View {
    @EnvironmentObject var ledger: LedgerStore

    var body: some View {
        VStack(spacing: 16) {
            MonthSelectionControl()
            
            Card {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Spent (This Month)").foregroundStyle(SwiftFinColor.textSecondary).font(.caption)
                        Text(String(format: "$%.2f", ledger.totalSpentThisMonth))
                            .font(.system(size: 28, weight: .bold))
                    }
                    Spacer()
                }
            }

            Card {
                Text("Spending Distribution").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DonutSpendingConnected()
                    .frame(height: 240)
                    .chartLegend(.hidden)
                LegendSimple(items: ledger.spentByCategoryThisMonth())
            }

            Card {
                Text("Spending by Category").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 12) {
                    ForEach(ledger.budgets) { b in
                        let used = ledger.usedForBudget(b.name)
                        CategoryRowBar(name: b.name, spent: used, budget: b.total)
                    }
                }
            }

            RecentExpenses()
        }
    }
}

// MARK: - Income Screen
struct IncomeScreen: View {
    @EnvironmentObject var ledger: LedgerStore
    var body: some View {
        VStack(spacing: 16) {
            MonthSelectionControl()
            
            Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Income (This Month)").foregroundStyle(SwiftFinColor.textSecondary).font(.caption)
                    Text(String(format: "$%.2f", ledger.totalIncomeThisMonth))
                        .font(.system(size: 28, weight: .bold))
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right").foregroundStyle(SwiftFinColor.positiveGreen)
                        Text("Monthly trend").foregroundStyle(SwiftFinColor.positiveGreen).font(.footnote)
                    }
                }
            }

            Card {
                Text("Income (last 6 months)").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                BarIncome()
                    .frame(height: 190)
            }

            Card {
                Text("Income Sources (This Month)").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 12) {
                    let total = max(ledger.totalIncomeThisMonth, 1)
                    let sources = Dictionary(grouping: ledger.incomeThisMonth, by: { $0.category })
                        .map { (name: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
                        .sorted { $0.amount > $1.amount }
                    ForEach(Array(sources.enumerated()), id: \.offset) { _, s in
                        HStack {
                            Label(s.name, systemImage: "creditcard.fill")
                            Spacer()
                            Text(String(format: "$%.0f", s.amount))
                        }
                        ProgressView(value: s.amount / total)
                            .tint(SwiftFinColor.accentBlue)
                    }
                }
            }

            RecentIncome()
        }
    }
}

// MARK: - Charts
struct MiniTrendChart: View {
    let data = (0..<8).map { i in (x: i, y: Double.random(in: 0.0...1.0)) }
    var body: some View {
        Chart(data, id: \.x) {
            LineMark(x: .value("t", $0.x), y: .value("v", $0.y))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(SwiftFinColor.accentBlue)
            AreaMark(x: .value("t", $0.x), y: .value("v", $0.y))
                .foregroundStyle(SwiftFinColor.accentBlue.opacity(0.25))
        }
        .chartXAxis(.hidden).chartYAxis(.hidden)
    }
}

struct BarCashFlow: View {
    let months = ["Jan","Feb","Mar","Apr","May","Jun"]
    let income = [1800, 2100, 2000, 2300, 2250, 2400]
    let expense = [1200, 1400, 1350, 1500, 1600, 1860]

    var body: some View {
        Chart {
            ForEach(Array(months.enumerated()), id: \.offset) { idx, m in
                BarMark(x: .value("Month", m), y: .value("Income", income[idx]))
                    .foregroundStyle(SwiftFinColor.accentBlue)
                BarMark(x: .value("Month", m), y: .value("Expense", expense[idx]))
                    .foregroundStyle(SwiftFinColor.textSecondary.opacity(0.5))
            }
        }
        .chartYAxisLabel("USD")
        .chartForegroundStyleScale([
            "Income": SwiftFinColor.accentBlue,
            "Expense": SwiftFinColor.textSecondary
        ])
    }
}

struct DonutSpendingConnected: View {
    @EnvironmentObject var ledger: LedgerStore
    private let palette: [Color] = [.blue, .green, .orange, .purple, .red, .teal, .yellow]
    var body: some View {
        let data = ledger.spentByCategoryThisMonth()
        let total = max(data.map(\.amount).reduce(0,+), 1)
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { i, row in
                SectorMark(angle: .value("Amount", row.amount), innerRadius: .ratio(0.62))
                    .foregroundStyle(palette[i % palette.count])
                    .annotation(position: .overlay) {
                        let p = row.amount / total
                        if p > 0.10 {
                            Text("\(Int(p * 100))%")
                                .font(.caption2).bold()
                        }
                    }
            }
        }
    }
}

// MARK: - Legend & Bars
struct LegendSimple: View {
    let items: [(name: String, amount: Double)]
    private let palette: [Color] = [.blue, .green, .orange, .purple, .red, .teal, .yellow]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items.indices, id: \.self) { i in
                HStack {
                    Circle().fill(palette[i % palette.count]).frame(width: 10, height: 10)
                    Text(items[i].name).font(.caption)
                    Spacer()
                    Text(String(format: "$%.0f", items[i].amount))
                        .font(.caption).foregroundStyle(SwiftFinColor.textSecondary)
                }
            }
        }
    }
}

struct CategoryRowBar: View {
    let name: String
    let spent: Double
    let budget: Double

    var over: Bool { spent > budget }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                Spacer()
                Text(String(format: "$%.0f / $%.0f", spent, max(budget, 1)))
                    .foregroundStyle(SwiftFinColor.textSecondary)
                    .font(.caption)
            }
            GeometryReader { geo in
                let w = geo.size.width
                let h: CGFloat = 10
                let maxV = max(spent, budget, 1)
                let spentW = w * spent / maxV
                let budW   = w * budget / maxV

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: h/2).fill(SwiftFinColor.surfaceAlt).frame(height: h)
                    RoundedRectangle(cornerRadius: h/2)
                        .fill(over ? SwiftFinColor.negativeRed : SwiftFinColor.accentBlue)
                        .frame(width: spentW, height: h)
                    Rectangle().fill(Color.white).frame(width: 2, height: h + 8).position(x: budW, y: h/2)
                }
            }
            .frame(height: 14)
        }
    }
}

// MARK: - Lists & Rows
struct RecentTransactions: View {
    let title: String
    let rows: [LedgerStore.Tx]
    var onViewAll: (() -> Void)? = nil

    var body: some View {
        Card {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if let onViewAll {
                    Button("View All >", action: onViewAll)
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textSecondary)
                }
            }
            VStack(spacing: 10) {
                ForEach(rows) { tx in
                    RowTx(icon: tx.kind == .expense ? "arrow.down.circle" : "arrow.up.circle",
                          title: tx.title,
                          subtitle: tx.category + " · " + tx.date.formatted(date: .abbreviated, time: .omitted),
                          amount: tx.kind == .expense ? -tx.amount : tx.amount)
                }
            }
        }
    }
}

struct RecentExpenses: View {
    @EnvironmentObject var ledger: LedgerStore
    var body: some View {
        Card {
            Text("Recent Expenses").font(.headline)
            VStack(spacing: 10) {
                ForEach(ledger.expensesThisMonth.sorted { $0.date > $1.date }.prefix(4)) { tx in
                    RowTx(icon: "arrow.down.circle",
                          title: tx.title,
                          subtitle: tx.category + " · " + tx.date.formatted(date: .abbreviated, time: .omitted),
                          amount: -tx.amount)
                }
            }
        }
    }
}

struct RecentIncome: View {
    @EnvironmentObject var ledger: LedgerStore
    var body: some View {
        Card {
            Text("Recent Income").font(.headline)
            VStack(spacing: 10) {
                ForEach(ledger.incomeThisMonth.sorted { $0.date > $1.date }.prefix(3)) { tx in
                    RowTx(icon: "arrow.up.circle",
                          title: tx.title,
                          subtitle: tx.category + " · " + tx.date.formatted(date: .abbreviated, time: .omitted),
                          amount: tx.amount)
                }
            }
        }
    }
}

struct RowTx: View {
    let icon: String
    let title: String
    let subtitle: String
    let amount: Double
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(SwiftFinColor.surfaceAlt).frame(width: 34, height: 34)
                Image(systemName: icon)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle).font(.caption).foregroundStyle(SwiftFinColor.textSecondary)
            }
            Spacer()
            Text(String(format: "%@$%.2f", amount < 0 ? "−" : "+", abs(amount)))
                .foregroundStyle(amount < 0 ? SwiftFinColor.negativeRed : SwiftFinColor.positiveGreen)
        }
    }
}

// MARK: - Budgets Section (connected)
struct BudgetsSectionConnected: View {
    @EnvironmentObject var ledger: LedgerStore
    @State private var showAddBudget = false

    var body: some View {
        Card {
            HStack {
                Text("Budgets").font(.headline)
                Spacer()
                Button {
                    showAddBudget = true
                } label: {
                    Image(systemName: "plus.circle.fill").font(.title2).tint(SwiftFinColor.accentBlue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                if ledger.budgets.isEmpty {
                    Text("No budgets set. Tap + to add one.").font(.subheadline)
                        .foregroundStyle(SwiftFinColor.textSecondary)
                } else {
                    ForEach(ledger.budgets) { budget in
                        let used = ledger.usedForBudget(budget.name)
                        BudgetRow(name: budget.name, spent: used, total: budget.total)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddBudget) {
            AddBudgetSheet().presentationDetents([.fraction(0.3)])
        }
    }
}

// MARK: - Budget Row
struct BudgetRow: View {
    let name: String
    let spent: Double
    let total: Double

    var overBudget: Bool { spent > total }
    var remaining: Double { total - spent }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name).font(.subheadline)
                Spacer()
                Text(String(format: "$%.0f / $%.0f", spent, total))
                    .font(.subheadline)
                    .foregroundStyle(SwiftFinColor.textSecondary)
            }

            // Progress Bar
            GeometryReader { geo in
                let w = geo.size.width
                let h: CGFloat = 8
                let progress = spent / total
                let spentW = min(w, w * progress)
                
                ZStack(alignment: .leading) {
                    // Fondo de la barra
                    RoundedRectangle(cornerRadius: h/2).fill(SwiftFinColor.surfaceAlt).frame(height: h)
                    
                    // Barra de progreso
                    RoundedRectangle(cornerRadius: h/2)
                        .fill(overBudget ? SwiftFinColor.negativeRed : SwiftFinColor.positiveGreen)
                        .frame(width: spentW, height: h)
                    
                    // Indicador de presupuesto (línea blanca)
                    if progress < 1.0 {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: h + 4)
                            .position(x: w, y: h/2)
                            .opacity(0.6)
                    }
                }
            }
            .frame(height: 12)
            
            // Remaining/Over Text
            HStack {
                if overBudget {
                    Text(String(format: "$%.0f Over Budget", abs(remaining)))
                        .font(.caption).bold()
                        .foregroundStyle(SwiftFinColor.negativeRed)
                } else {
                    Text(String(format: "$%.0f Remaining", remaining))
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textSecondary)
                }
                Spacer()
            }
        }
    }
}


// MARK: - Reports Screen
struct ReportsScreen: View {
    @EnvironmentObject var ledger: LedgerStore
    
    var body: some View {
        VStack(spacing: 16) {
            MonthSelectionControl()
            
            Card {
                Text("Monthly Summary").font(.title2).frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Income").font(.headline)
                        Text(String(format: "+$%.2f", ledger.totalIncomeThisMonth))
                            .font(.title3).bold()
                            .foregroundStyle(SwiftFinColor.positiveGreen)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Expenses").font(.headline)
                        Text(String(format: "-$%.2f", ledger.totalSpentThisMonth))
                            .font(.title3).bold()
                            .foregroundStyle(SwiftFinColor.negativeRed)
                    }
                }
                Divider()
                HStack {
                    Text("Net").font(.title3).bold()
                    Spacer()
                    Text(String(format: "%@$%.2f", ledger.netThisMonth < 0 ? "−" : "+", abs(ledger.netThisMonth)))
                        .font(.title3).bold()
                        .foregroundStyle(ledger.netThisMonth < 0 ? SwiftFinColor.negativeRed : SwiftFinColor.positiveGreen)
                }
            }
            
            Card {
                Text("Spending by Category").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DonutSpendingConnected().frame(height: 240).chartLegend(.hidden)
                LegendSimple(items: ledger.spentByCategoryThisMonth())
            }
            
            Card {
                Text("Income Distribution").font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    let total = max(ledger.totalIncomeThisMonth, 1)
                    let sources = Dictionary(grouping: ledger.incomeThisMonth, by: { $0.category })
                        .map { (name: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
                        .sorted { $0.amount > $1.amount }
                    
                    if sources.isEmpty {
                        Text("No income recorded this month.")
                            .foregroundStyle(SwiftFinColor.textSecondary)
                    } else {
                        ForEach(Array(sources.enumerated()), id: \.offset) { _, s in
                            HStack {
                                Label(s.name, systemImage: "briefcase.fill")
                                Spacer()
                                Text(String(format: "$%.0f (%.0f%%)", s.amount, (s.amount / total) * 100))
                            }
                            ProgressView(value: s.amount / total)
                                .tint(SwiftFinColor.positiveGreen)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Sheets (Modals)

/// Add New Expense
struct AddExpenseSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ledger: LedgerStore
    
    @State private var title: String = ""
    @State private var amount: Double? = nil
    @State private var category: String = "Food"
    
    let categories = ["Food", "Transport", "Bills", "Entertainment", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Description (e.g., Coffee)", text: $title)
                    TextField("Amount (USD)", value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) {
                            Text($0)
                        }
                    }
                }
            }
            .navigationTitle("New Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let amount = amount, amount > 0, !title.isEmpty {
                            ledger.addExpense(title: title, category: category, amount: amount)
                            dismiss()
                        }
                    }
                    .disabled(amount == nil || amount! <= 0 || title.isEmpty)
                    .bold()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

/// Add New Income
struct AddIncomeSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ledger: LedgerStore
    
    @State private var title: String = ""
    @State private var amount: Double? = nil
    @State private var category: String = "Salary"
    
    let categories = ["Salary", "Freelance", "Investment", "Gift", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Source (e.g., Monthly Paycheck)", text: $title)
                    TextField("Amount (USD)", value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) {
                            Text($0)
                        }
                    }
                }
            }
            .navigationTitle("New Income")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let amount = amount, amount > 0, !title.isEmpty {
                            ledger.addIncome(title: title, category: category, amount: amount)
                            dismiss()
                        }
                    }
                    .disabled(amount == nil || amount! <= 0 || title.isEmpty)
                    .bold()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

/// Add New Budget
struct AddBudgetSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ledger: LedgerStore
    
    @State private var name: String = ""
    @State private var total: Double? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section("Budget Details") {
                    TextField("Budget Name (e.g., Groceries, Rent)", text: $name)
                    TextField("Monthly Limit (USD)", value: $total, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("New Budget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let total = total, total > 0, !name.isEmpty {
                            ledger.addBudget(name: name, total: total)
                            dismiss()
                        }
                    }
                    .disabled(total == nil || total! <= 0 || name.isEmpty)
                    .bold()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - View All Expenses Sheet
struct ViewAllExpensesView: View {
    @EnvironmentObject var ledger: LedgerStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ledger.expensesThisMonth.sorted { $0.date > $1.date }) { tx in
                    RowTx(icon: "arrow.down.circle",
                          title: tx.title,
                          subtitle: tx.category + " · " + tx.date.formatted(date: .abbreviated, time: .omitted),
                          amount: -tx.amount)
                }
                .listRowBackground(SwiftFinColor.surface) // Para mantener la estética oscura en la lista
            }
            .navigationTitle("All Expenses")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .listStyle(.plain)
            .background(SwiftFinColor.bgPrimary.ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
    }
}


// MARK: - Charts - Part 2

struct BarIncome: View {
    // Datos de ejemplo para ingresos mensuales (últimos 6 meses, incluyendo el mes actual simulado)
    let months = ["May","Jun","Jul","Aug","Sep","Oct"] // Ejemplo
    let incomeData = [2000, 2150, 2400, 2200, 2500, 3580.0] // 3580 es la suma del demo: 3200+380
    
    var body: some View {
        Chart {
            ForEach(Array(months.enumerated()), id: \.offset) { idx, m in
                BarMark(x: .value("Month", m), y: .value("Income", incomeData[idx]))
                    .foregroundStyle(SwiftFinColor.positiveGreen)
            }
        }
        .chartYAxisLabel("USD")
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}
