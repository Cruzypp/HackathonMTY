import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @State private var selectedTab = 0
    @State private var didPreload = false
    @State private var showAntExpensesPopup = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Overview
            NavigationStack {
                ZStack {
                    SwiftFinColor.bgPrimary.ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            OverviewScreen()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .navigationTitle("Overview")
                .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Overview", systemImage: "chart.pie.fill")

            }
            
            // Tab 2: Expenses
            NavigationStack {
                ZStack {
                    SwiftFinColor.bgPrimary.ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ExpensesScreen()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .navigationTitle("Expenses")
                .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Expenses", systemImage: "creditcard.fill")
            }
            .tag(1)
            
            // Tab 3: Income
            NavigationStack {
                ZStack {
                    SwiftFinColor.bgPrimary.ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            IncomeScreen()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .navigationTitle("Income")
                .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Income", systemImage: "dollarsign.circle.fill")
            }
            .tag(2)
            
            // Tab 4: Chat with FinBot
            NavigationStack {
                ChatView()
            }
            .tabItem {
                Label("FinBot", systemImage: "brain.head.profile")
            }
            .tag(3)
        }
        .accentColor(SwiftFinColor.capitalOneRed) // Tabs en rojo Capital One
        .onAppear {
            // Preload accounts and transactions once
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
