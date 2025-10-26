import SwiftUI

struct LoginView: View {
    // Colores de marca Capital One (oficiales)
    let capitalOneBlue = Color(hex: "#004977")      // Capital One Primary Blue
    let capitalOneRed = Color(hex: "#D92228")       // Capital One Primary Red
    let capitalOneNavy = Color(hex: "#001F3F")      // Navy oscuro para fondo
    let accentBlue = Color(hex: "#0099DD")          // Capital One Bright Blue

    // Estados para los campos de texto
    @State private var email: String = ""
    @State private var password: String = ""
    
    // Estado para la lógica de login
    @State private var isLoggingIn: Bool = false
    @State private var loginFailed: Bool = false
    
    // Binding del ContentView para avisar que el login fue exitoso
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        ZStack {
            // Fondo con gradiente Capital One oficial
            LinearGradient(
                colors: [capitalOneNavy, capitalOneBlue],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Efecto liquid glass - círculos flotantes con colores Capital One
            Circle()
                .fill(capitalOneRed.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(accentBlue.opacity(0.2))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: 150, y: 300)
            
            VStack(spacing: 20) {
                Spacer()
                
                // 1. Logo de tu App
                ZStack {
                    Circle()
                        .fill(accentBlue.opacity(0.25))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                    
                    Image(systemName: "bird.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, accentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.bottom, 10)
                
                Text("Welcome to SwiftFin")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                
                Text("Your AI financial analyst.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()
                
                VStack(spacing: 16) {
                    // 2. Campo de Email con efecto glass
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(accentBlue)
                        TextField("", text: $email)
                            .foregroundStyle(.white)
                            .tint(accentBlue)
                            .placeholder(when: email.isEmpty) {
                                Text("Email (admin@admin)")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: loginFailed ? capitalOneRed.opacity(0.5) : .clear, radius: 10)
                    )
                    
                    // 3. Campo de Contraseña con efecto glass
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(accentBlue)
                        SecureField("", text: $password)
                            .foregroundStyle(.white)
                            .tint(accentBlue)
                            .placeholder(when: password.isEmpty) {
                                Text("Password (admin)")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: loginFailed ? capitalOneRed.opacity(0.5) : .clear, radius: 10)
                    )
                    
                    // 4. Mensaje de Error
                    if loginFailed {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(capitalOneRed)
                            Text("Email o contraseña incorrectos.")
                                .font(.caption)
                                .foregroundStyle(capitalOneRed)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 8)
                
                Spacer()
                Spacer()
                
                // 5. Botón de Login con efecto glass y gradiente
                Button(action: performLogin) {
                    HStack {
                        if isLoggingIn {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Log In")
                                .font(.headline.bold())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        ZStack {
                            // Capa de fondo con gradiente
                            LinearGradient(
                                colors: [capitalOneRed, capitalOneRed.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            // Efecto glass overlay
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: capitalOneRed.opacity(0.5), radius: 10, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .disabled(isLoggingIn)
                .scaleEffect(isLoggingIn ? 0.95 : 1.0)
                
            }
            .padding(.horizontal, 30)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: loginFailed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoggingIn)
    }
    
    // --- Lógica del Login ---
    func performLogin() {
        Task {
            isLoggingIn = true
            loginFailed = false
            
            // Simula una llamada de red
            try? await Task.sleep(for: .seconds(1))
            
            // La lógica de autenticación
            if email == "admin@admin" && password == "admin" {
                // ¡Éxito!
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isLoggedIn = true
                }
            } else {
                // Falla
                withAnimation {
                    loginFailed = true
                }
            }
            
            isLoggingIn = false
        }
    }
}

// --- View Modifier para Placeholder (Helper) ---
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: .leading) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
        .preferredColorScheme(.light)
}
