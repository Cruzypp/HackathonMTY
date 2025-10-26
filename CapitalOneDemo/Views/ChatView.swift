import SwiftUI

struct ChatView: View {
    // 1. Referencia al ViewModel
    @StateObject private var viewModel = ChatViewModel()
    
    // 2. Variable para el campo de texto
    @State private var textInput: String = ""
    
    // 3. variable para datos de usuario
    @EnvironmentObject var ledgerViewModel: LedgerViewModel
    
    var body: some View {
        ZStack {
            // Fondo con gradiente
            LinearGradient(
                colors: [SwiftFinColor.bgPrimary, SwiftFinColor.surface.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- Área de Mensajes ---
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) {
                        // Auto-scroll al último mensaje
                        if let lastMessageId = viewModel.messages.last?.id {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                scrollViewProxy.scrollTo(lastMessageId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // --- Indicador de "Escribiendo..." ---
                if viewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(SwiftFinColor.accentBlue)
                        Text("FinBot is typing...")
                            .foregroundStyle(SwiftFinColor.textPrimary)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        SwiftFinColor.surface.opacity(0.5)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // --- Barra de Entrada de Texto con efecto glass ---
                HStack(spacing: 12) {
                    
                    // <-- CAMBIO AQUI (1 y 2): Se usa 'prompt' para el placeholder blanco
                    TextField("", text: $textInput, prompt:
                                Text("Ask FinBot... (e.g., 'What is inflation?')")
                        .foregroundStyle(.white), axis: .vertical // 1. Placeholder blanco
                    )
                        .lineLimit(3)
                        .padding(12)
                        .tint(SwiftFinColor.accentBlue)
                        .foregroundStyle(.white) // 2. Texto de entrada (tipeado) blanco
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(SwiftFinColor.surface.opacity(0.8))
                                
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.05), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), SwiftFinColor.divider],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    Button(action: sendMessage) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: textInput.isEmpty ?
                                            [SwiftFinColor.surfaceAlt, SwiftFinColor.surface] :
                                            [SwiftFinColor.accentBlue, Color(hex: "#00559A")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            if !textInput.isEmpty {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.2), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                            }
                            
                            Image(systemName: "arrow.up")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white) // <-- CAMBIO AQUI (3): Flecha siempre blanca
                        }
                        .shadow(color: textInput.isEmpty ? .clear : SwiftFinColor.accentBlue.opacity(0.4), radius: 8, y: 4)
                    }
                    .disabled(textInput.isEmpty || viewModel.isLoading)
                    .scaleEffect(textInput.isEmpty || viewModel.isLoading ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: textInput.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        SwiftFinColor.bgPrimary.opacity(0.98)
                        
                        LinearGradient(
                            colors: [.white.opacity(0.03), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .navigationTitle("FinBot")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setContext(ledgerViewModel.financialSummary)
            print("Chat context set to: \(ledgerViewModel.financialSummary)")
        }
    }
    
    func sendMessage() {
        let messageText = textInput
        textInput = "" // Limpia el campo de texto
        
        // Llama al ViewModel en un Task (asíncrono)
        Task {
            await viewModel.sendMessage(messageText)
        }
    }
}

#Preview {
    NavigationView { // Envuelve en NavigationView para ver el título
        ChatView()
            // Asumiendo que tienes colores definidos, si no, reemplázalos
            // .environmentObject(ChatViewModel())
            // .preferredColorScheme(.dark)
    }
}

/*
// --- Necesitarías algo como esto para que el Preview compile ---
// (Puedes ignorar esto si ya lo tienes en tu proyecto)
struct SwiftFinColor {
    static let bgPrimary = Color.black
    static let surface = Color.gray.opacity(0.5)
    static let surfaceAlt = Color.gray.opacity(0.3)
    static let accentBlue = Color.blue
    static let textPrimary = Color.white
    static let textSecondary = Color.gray
    static let divider = Color.gray.opacity(0.2)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct MessageBubble: View {
    let message: Message
    var body: some View {
        Text(message.content)
            .padding()
            .background(message.isFromUser ? Color.blue : Color.gray.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

struct Message: Identifiable, Equatable {
    let id: UUID = UUID()
    let content: String
    let isFromUser: Bool
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = [
        .init(content: "Hello! How can I help you with your finances today?", isFromUser: false)
    ]
    @Published var isLoading: Bool = false
    
    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }
        messages.append(Message(content: text, isFromUser: true))
        isLoading = true
        
        // Simula una respuesta de red
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        messages.append(Message(content: "This is a simulated response about '\(text)'.", isFromUser: false))
        isLoading = false
    }
}
*/
