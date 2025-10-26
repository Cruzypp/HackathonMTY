import SwiftUI

struct ContentView: View {
    // 1. Estado principal de la app: ¿Está el usuario logueado?
    // Para el hackathon, empezamos en 'false'.
    // Para pruebas, puedes ponerlo en 'true' para saltarte el login.
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        ZStack {
            if isLoggedIn {
                // 2. Si está logueado, muestra la app principal
                MainAppView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                // 3. Si no, muestra la pantalla de Login
                LoginView(isLoggedIn: $isLoggedIn)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isLoggedIn)
    }
}

#Preview {
    ContentView()
        .environmentObject(PreviewMocks.ledger)
        .environmentObject(PreviewMocks.monthSelector)
        .preferredColorScheme(.dark)
}
