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
                            .foregroundStyle(SwiftFinColor.textSecondary)
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
                    TextField("Ask FinBot... (e.g., 'What is inflation?')", text: $textInput, axis: .vertical)
                        .lineLimit(3)
                        .padding(12)
                        .foregroundStyle(SwiftFinColor.textPrimary)
                        .tint(SwiftFinColor.accentBlue)
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
                                .foregroundStyle(textInput.isEmpty ? SwiftFinColor.textSecondary : .white)
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
    }
}
