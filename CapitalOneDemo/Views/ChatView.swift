import SwiftUI

struct ChatView: View {
    // 1. Referencia al ViewModel
    @StateObject private var viewModel = ChatViewModel()
    
    // 2. Variable para el campo de texto
    @State private var textInput: String = ""
    
    var body: some View {
        VStack {
            // --- Área de Mensajes ---
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id) // ID para poder auto-scroll
                        }
                    }
                }
                .onChange(of: viewModel.messages.count) {
                    // Auto-scroll al último mensaje
                    if let lastMessageId = viewModel.messages.last?.id {
                        withAnimation {
                            scrollViewProxy.scrollTo(lastMessageId, anchor: .bottom)
                        }
                    }
                }
            }
            
            // --- Indicador de "Escribiendo..." ---
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .padding(.leading)
                    Text("FinBot is typing...")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // --- Barra de Entrada de Texto ---
            HStack {
                TextField("Ask FinBot... (e.g., 'What is inflation?')", text: $textInput, axis: .vertical)
                    .lineLimit(3)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundStyle(textInput.isEmpty ? .gray : .blue)
                }
                .disabled(textInput.isEmpty || viewModel.isLoading)
            }
            .padding()
        }
        .navigationTitle("FinBot")
        .navigationBarTitleDisplayMode(.inline)
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
