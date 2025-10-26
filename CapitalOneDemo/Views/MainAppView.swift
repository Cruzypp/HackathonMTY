import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @State private var selectedTab = 0
    @State private var didPreload = false
    @State private var showAntExpensesPopup = false

    // Altura del header superpuesto dentro del ScrollView
    private let overlayHeaderHeight: CGFloat = 60

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: - Tab 1: Overview
            NavigationStack {
                ZStack {
                    // Fondo general de la pantalla (puedes dejarlo o quitarlo)
                    SwiftFinColor.bgPrimary.ignoresSafeArea()

                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            // Contenido real
                            VStack(spacing: 16) {
                                OverviewScreen()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                            // Dejamos espacio arriba para que el header (overlay dentro del ScrollView) no tape nada
                            .padding(.top, overlayHeaderHeight + 8)

                            // === Overlay DENTRO del ScrollView (se desplaza y “se queda” en su posición del contenido) ===
                            HStack(spacing: 8) {
                                Text("Overview")
                                    .font(.headline)
                                    .foregroundStyle(SwiftFinColor.textDark)

                                Image(.captwo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 38, height: 38)
                                    .offset(x: 100, y: -58)
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 16)
                            .allowsHitTesting(false)
                        }
                    }
                    .background(Color.clear) // SIN fondo para el ScrollView
                    .scrollIndicators(.hidden)
                }
                .navigationTitle("Overview")
                .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Overview", systemImage: "chart.pie.fill")
            }
            .tag(0)

            // MARK: - Tab 2: Expenses
            NavigationStack {
                ZStack {
                    SwiftFinColor.bgPrimary.ignoresSafeArea()

                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            VStack(spacing: 16) {
                                ExpensesScreen()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                            .padding(.top, overlayHeaderHeight + 8)

                            HStack(spacing: 8) {
                                Text("Expenses")
                                    .font(.headline)
                                    .foregroundStyle(SwiftFinColor.textDark)

                                Image(.captwo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 38, height: 38)
                                    .offset(x: 100, y: -58)
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 16)
                            .allowsHitTesting(false)
                        }
                    }
                    .background(Color.clear) // SIN fondo para el ScrollView
                    .scrollIndicators(.hidden)
                }
                .navigationTitle("Expenses")
                .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Expenses", systemImage: "creditcard.fill")
            }
            .tag(1)

            // MARK: - Tab 3: Income
            NavigationStack {
                ZStack {
                    SwiftFinColor.bgPrimary.ignoresSafeArea()

                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            VStack(spacing: 16) {
                                IncomeScreen()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                            .padding(.top, overlayHeaderHeight + 8)

                            HStack(spacing: 8) {
                                Text("Income")
                                    .font(.headline)
                                    .foregroundStyle(SwiftFinColor.textDark)

                                Image(.captwo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 38, height: 38)
                                    .offset(x: 80, y: -58)
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 16)
                            .allowsHitTesting(false)
                        }
                    }
                    .background(Color.clear) // SIN fondo para el ScrollView
                    .scrollIndicators(.hidden)
                }
                .navigationTitle("Income")
                .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Income", systemImage: "dollarsign.circle.fill")
            }
            .tag(2)

            // MARK: - Tab 4: FinBot
            NavigationStack {
                ChatView()
            }
            .tabItem {
                Label("FinBot", systemImage: "sparkles")
            }
            .tag(3)
        }
        .accentColor(SwiftFinColor.capitalOneRed)
        .onAppear {
            guard !didPreload else { return }
            didPreload = true
            let apiKey = AuthStore.shared.readApiKey() ?? LocalSecrets.nessieApiKey
            let customerId = AuthStore.shared.readCustomerId() ?? LocalSecrets.nessieCustomerId
            Preloader.preloadAll(customerId: customerId, apiKey: apiKey, into: ledger)
        }
        .sheet(isPresented: $showAntExpensesPopup) {
            AntExpensesPopupView()
                .environmentObject(ledger)
        }
    }
}

#Preview {
    MainAppView()
        .environmentObject(PreviewMocks.ledger)
        .environmentObject(PreviewMocks.monthSelector)
}
