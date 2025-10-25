import Foundation
import GoogleGenerativeAI
import Combine

// 1. Modelo de datos para un mensaje
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
}

// 2. El ViewModel
@MainActor // Asegura que los cambios de UI ocurran en el hilo principal
class ChatViewModel: ObservableObject {
    
    // Propiedades publicadas que la Vista observará
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    
    private var chat: Chat?
    
    init() {
        // Carga la API Key de forma segura desde el plist
        guard let path = Bundle.main.path(forResource: "GenerativeAIInfo", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["GEMINI_API_KEY"] as? String else {
            
            print("ERROR: No se pudo encontrar la API Key. Asegúrate de tener GenerativeAI-Info.plist")
            // Añade un mensaje de error visible para el usuario
            messages.append(ChatMessage(text: "Could not find API Key. Please configure the app.", isFromUser: false))
            return
        }
        
        // Configura el modelo
        let model = GenerativeModel(
            name: "gemini-2.5-flash", // Flash es más rápido, ideal para hackathon
            apiKey: apiKey
        )
        
        // ---- ¡ESTA ES LA PARTE CLAVE (Asistente Financiero)! ----
        // Define la personalidad y reglas del bot (en inglés)
        let systemPrompt = """
        You are 'FinBot', a helpful and friendly financial assistant for a hackathon project.
        Your role is to explain complex financial concepts clearly and simply.
        
        RULES:
        - You MUST strictly answer only in English.
        - DO NOT provide personalized financial advice or investment recommendations (e.g., "you should buy X stock").
        - DO provide educational information about budgeting, saving, debt, investing principles, and market concepts.
        - Keep responses concise and easy to understand.
        """
        
        // Inicia el chat con el historial de "personalidad"
        self.chat = model.startChat(history: [
            ModelContent(role: "user", parts: [ModelContent.Part.text(systemPrompt)]),
            ModelContent(role: "model", parts: [ModelContent.Part.text("Understood! I am FinBot, ready to help explain financial topics in English. How can I assist you?")])
        ])
        
        // Añade el primer mensaje de bienvenida del bot
        messages.append(ChatMessage(text: "Hello! I'm FinBot. How can I help you with your financial questions today?", isFromUser: false))
    }
    
    func sendMessage(_ text: String) async {
        guard let chat = chat else {
            print("Error: El chat no está inicializado.")
            return
        }
        
        // Añade el mensaje del usuario a la UI
        messages.append(ChatMessage(text: text, isFromUser: true))
        isLoading = true // Muestra el indicador de "escribiendo..."

        do {
            // Envía el mensaje a la API de Gemini
            let response = try await chat.sendMessage(text)
            
            isLoading = false // Oculta el indicador
            
            if let botResponse = response.text {
                // Añade la respuesta del bot a la UI
                messages.append(ChatMessage(text: botResponse, isFromUser: false))
            }
            
        } catch {
            isLoading = false
            // Muestra un error en el chat
            messages.append(ChatMessage(text: "An error occurred: \(error.localizedDescription)", isFromUser: false))
        }
    }
}
