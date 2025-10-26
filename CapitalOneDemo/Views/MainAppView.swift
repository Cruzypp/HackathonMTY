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
                .padding()
                .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Overview", systemImage: "chart.pie.fill")

            }
            .overlay(){
                Image(.captwo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .offset(x: 0, y: -290)
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
            .scrollContentBackground(.hidden)
            .overlay(){
                Image(.captwo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .offset(x: 0, y: -290)
            }
            
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
            .overlay(){
                Image(.captwo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .offset(x: -35, y: -290)
            }
            
            // Tab 4: Chat with FinBot
            NavigationStack {
                ChatView()
            }
            .tabItem {
                Label("FinBot", systemImage: "sparkles")
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
