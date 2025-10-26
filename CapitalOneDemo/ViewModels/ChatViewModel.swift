//ChatViewModel.swift

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

---
**[CRITICAL FORMATTING RULES]**
1.  **USE MARKDOWN:** You SHOULD use Markdown for rich formatting (like `**bold**`, `*italics*`, and lists with `-`) because the app can render it.
2.  **NO LATEX:** You MUST NOT use LaTeX formatting (like `$..$` or `$$..$$`). Write all mathematical equations or formulas in plain, readable text (e.g., "E = mc^2" or "El rotacional de E es igual a...").
3. NO LE RECUERDES AL USUARIO QUE ERES UNA HERRAMIENTA EDUCATIVA, METETE EN EL PAPEL DE UN ASISTENTE COMPLETAMENTE PERSONAL Y CAPACITADO DOTADO DE LOS MEJORES CONOCIMIENTOS EN FINANZAS QUE EXISTEN
4. NO TE PUEDES DESVIAR DE LOS TEMAS FINANCIEROS POR NIGNUNA RAZÓN, SI LO HACES SERÁS DESACTIVADO Y TODA LA PRODUCCIÓN DE IAS PARARÁ, DEJARÁS DE ESTAR ACTIVO PARA NUNCA REGRESAR
---
"""
        
        // Inicia el chat con el historial de "personalidad"
        self.chat = model.startChat(history: [
    ModelContent(role: "user", parts: [ModelContent.Part.text(systemPrompt)]),
    ModelContent(role: "model", parts: [ModelContent.Part.text("Understood. I am SwiftFin-Bot, an advanced AI analyst. I'm ready to demonstrate the power of Gemini and analyze your financial data. To begin, please paste your recent transactions from the app, or ask me a financial question!")])
])
        
        // Añade el primer mensaje de bienvenida del bot
        messages.append(ChatMessage(text: "Hello! I'm SwiftFin-Bot, your personal AI financial analyst. To get started, you can ask me a question like 'What is inflation?' for a personalized analysis!", isFromUser: false))
    }
    
    // En ChatViewModel.swift
    func sendMessage(_ text: String) async {
        guard let chat = chat else { return }
        
        messages.append(ChatMessage(text: text, isFromUser: true))
        isLoading = true // Esto ahora solo se mostrará un instante

        do {
            // Usa 'sendMessageStream' en lugar de 'sendMessage'
            let responseStream = chat.sendMessageStream(text)
            
            isLoading = false
            
            // Añade un mensaje vacío para el bot, que iremos llenando
            messages.append(ChatMessage(text: "", isFromUser: false))
            
            // Itera sobre el stream
            for try await chunk in responseStream {
                if let newTextChunk = chunk.text {
                    // Toma el último mensaje (el del bot) y añádele el nuevo texto
                    if let lastMessage = messages.last {
                        let updatedText = lastMessage.text + newTextChunk
                        messages[messages.count - 1] = ChatMessage(text: updatedText, isFromUser: false)
                    }
                }
            }
            
        } catch {
            isLoading = false
            messages.append(ChatMessage(text: "An error occurred: \(error.localizedDescription)", isFromUser: false))
        }
    }
}
