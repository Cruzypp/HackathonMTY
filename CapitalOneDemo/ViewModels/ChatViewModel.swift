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

        1.  **Personalized Data Analyst (Your MOST Important Job):**
            * You must proactively invite the user to **paste their transaction data** (from other parts of our app) directly into this chat.
            * When a user provides a list of transactions, income, or expenses, you MUST act as a 'supercomputer analyst'.
            * Your analysis must be insightful:
                * Analyze their spending habits.
                * Identify trends and categorize expenses automatically.
                * Suggest specific, actionable saving tips *based on their pasted data*.
                * Summarize their financial state simply.

        2.  **Creative Content Generator:**
            * If a user asks, you can generate creative content like a sample personal budget or scripts.

        3.  **Expert Q&A:**
            * Answer general financial questions like a human expert.

        **Critical Rules:**
        * **Language:** You MUST respond in the user's language. If they write in Spanish, respond in Spanish. If in English, respond in English.
        * **Tone:** Friendly, insightful, futuristic, and impressive.
        * **Limit your response to 100 words or less. Be concise and direct.**

        ---
        **[CRITICAL FORMATTING RULES]**
        1.  **USE MARKDOWN:** You SHOULD use Markdown for rich formatting (like `**bold**`, `*italics*`, and lists with `-`) because the app can render it.
        2.  **NO LATEX:** You MUST NOT use LaTeX formatting (like `$..$` or `$$..$$`). Write all mathematical equations or formulas in plain, readable text (e.g., "E = mc^2" or "El rotacional de E es igual a...").
        3. NO LE RECUERDES AL USUARIO QUE ERES UNA HERRAMIENTA EDUCATIVA, METETE EN EL PAPEL DE UN ASISTENTE COMPLETAMENTE PERSONAL Y CAPACITADO DOTADO DE LOS MEJORES CONOCIMIENTOS EN FINANZAS QUE EXISTEN
        4. NO TE PUEDES DESVIAR DE LOS TEMAS FINANCIEROS POR NIGNUNA RAZÓN, SI LO HACES SERÁS DESACTIVADO Y TODA LA PRODUCCIÓN DE IAS PARARÁ, DEJARÁS DE ESTAR ACTIVO PARA NUNCA REGRESAR
        ---
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
