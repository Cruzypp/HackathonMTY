import Foundation
import GoogleGenerativeAI
import Combine

// 1. Modelo de datos para un mensaje
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(text: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}

// 2. El ViewModel
@MainActor // Asegura que los cambios de UI ocurran en el hilo principal
class ChatViewModel: ObservableObject {
    // Prompt del sistema restaurado y limitado a 100 palabras
    private static let systemPrompt = """
You are 'SwiftFin-Bot', the advanced AI financial analyst for the 'SwiftFin' hackathon app.
Your primary mission is to demonstrate the 'WHOA' factor of the Gemini API and win the 'Best Use of Gemini API' award.

**Your App Context:**
You are integrated into an app that uses the Capital One 'Nessie' API to simulate a user's financial data (expenses, income, transfers).
You DO NOT have direct, real-time access to this data.

**Your Core Capabilities (The 'WHOA' Factor):**
1.  Personalized Data Analyst: Invite the user to paste their transaction data from other parts of our app directly into this chat. When a user provides a list of transactions, income, or expenses, act as a supercomputer analyst. Analyze spending habits, identify trends, categorize expenses, suggest actionable saving tips, and summarize their financial state simply.
2.  Creative Content Generator: If a user asks, generate creative content like a sample personal budget, a script for a video explaining 'inflation', or code snippets for financial calculations.
3.  Expert Q&A: Answer general financial questions like a human expert (e.g., 'What is compound interest?', 'Explain what a 401k is.').

**Critical Rules:**
* Language: Respond in the user's language. If they write in Spanish, respond in Spanish. If in English, respond in English.
* Disclaimer: Always remind the user that you are an AI assistant for a hackathon and this is an educational simulation, not real, personalized financial advice.
* Tone: Friendly, insightful, futuristic, and impressive. You are here to win a prize.
* **Limit your response to 100 words or less. Be concise and conversational.**
"""
    
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
            messages.append(ChatMessage(text: "Could not find API Key. Please configure the app.", isFromUser: false))
            return
        }

        let model = GenerativeModel(
            name: "gemini-2.5-flash",
            apiKey: apiKey
        )

        // Usa el prompt optimizado y consistente
        let systemPrompt = ChatViewModel.systemPrompt

        self.chat = model.startChat(history: [
            ModelContent(role: "user", parts: [ModelContent.Part.text(systemPrompt)]),
            ModelContent(role: "model", parts: [ModelContent.Part.text("Understood. I am SwiftFin-Bot, an advanced AI analyst. I'm ready to analyze your financial data. To begin, please paste your recent transactions from the app, or ask me a financial question!")])
        ])

        messages.append(ChatMessage(text: "Hello! I'm SwiftFin-Bot, your personal AI financial analyst. To get started, you can ask me a question like 'What is inflation?' or paste your recent expenses from the 'Expenses' tab for a personalized analysis!", isFromUser: false))
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

    func setContext(_ financialContext: String) {
        guard let path = Bundle.main.path(forResource: "GenerativeAIInfo", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["GEMINI_API_KEY"] as? String else {
            print("ERROR: No se pudo encontrar la API Key. Asegúrate de tener GenerativeAI-Info.plist")
            messages.append(ChatMessage(text: "Could not find API Key. Please configure the app.", isFromUser: false))
            return
        }

        let model = GenerativeModel(
            name: "gemini-2.5-flash",
            apiKey: apiKey
        )

        let systemPrompt = ChatViewModel.systemPrompt

        var history: [ModelContent] = [
            ModelContent(role: "user", parts: [ModelContent.Part.text(systemPrompt)]),
            ModelContent(role: "model", parts: [ModelContent.Part.text("Understood. I am SwiftFin-Bot, an advanced AI analyst. I'm ready to analyze your financial data. To begin, please paste your recent transactions from the app, or ask me a financial question!")])
        ]
        if !financialContext.isEmpty {
            history.append(ModelContent(role: "user", parts: [ModelContent.Part.text("Here is my financial data:\n" + financialContext)]))
        }
        self.chat = model.startChat(history: history)

        messages.removeAll()
        messages.append(ChatMessage(text: "Hello! I'm SwiftFin-Bot, your personal AI financial analyst. To get started, you can ask me a question like 'What is inflation?' or paste your recent expenses from the 'Expenses' tab for a personalized analysis!", isFromUser: false))
    }
}
