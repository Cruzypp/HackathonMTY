
import Foundation
import GoogleGenerativeAI
import Combine

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    private var chat: Chat?

    func initialPrompt(financialData: FinancialSummary?) -> String {
        guard let data = financialData else {
            return """
            Financial Context:
            - No financial data available yet.
            - Please connect your account or paste your transactions for analysis.
            """
        }
        return """
        Financial Context:
        - Total Balance: $\(data.totalBalance)
        - Ant Expenses: $\(data.totalAntExpenses)
        - Top Categories: \(data.topCategories.isEmpty ? "No categories found" : data.topCategories.joined(separator: ", "))
        - Recent Transactions: \(data.recentTransactions.isEmpty ? "No transactions found" : data.recentTransactions.map { "\($0.title): $\($0.amount)" }.joined(separator: ", "))
        """
    }

    init(ledger: LedgerViewModel? = nil) {
        guard let path = Bundle.main.path(forResource: "GenerativeAIInfo", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["GEMINI_API_KEY"] as? String else {
            print("ERROR: No se pudo encontrar la API Key. Asegúrate de tener GenerativeAI-Info.plist")
            messages.append(ChatMessage(text: "Could not find API Key. Please configure the app.", isFromUser: false))
            return
        }

        let financialContext = ledger?.financialSummary()
        let contextPrompt = initialPrompt(financialData: financialContext)

        // Debug: imprime el contexto financiero en consola
        print("[DEBUG] Financial Context for ChatViewModel:\n\(contextPrompt)")

        let model = GenerativeModel(
            name: "gemini-2.5-flash",
            apiKey: apiKey
        )

        let systemPrompt = """
        You are 'SwiftFin-Bot', the advanced AI financial analyst for the 'SwiftFin' hackathon app.
        Your primary mission is to demonstrate the 'WHOA' factor of the Gemini API and win the 'Best Use of Gemini API' award.

        **Your App Context:**
        You are integrated into an app that uses the Capital One 'Nessie' API to simulate a user's financial data (expenses, income, transfers).
        You DO NOT have direct, real-time access to this data.

        **User Financial Context:**
        \(contextPrompt)

        **Your Core Capabilities (The 'WHOA' Factor):**
        1.  **Personalized Data Analyst (Your MOST Important Job):**
            * You must proactively invite the user to **paste their transaction data** (from other parts of our app) directly into this chat.
            * When a user provides a list of transactions, income, or expenses, you MUST act as a 'supercomputer analyst'.
            * Your analysis must be insightful:
                * Analyze their spending habits (e.g., "I see 60% of your 'dining out' spending is on weekends.").
                * Identify trends and categorize expenses automatically.
                * Suggest specific, actionable saving tips *based on their pasted data* (e.g., "You could save $50/month by reducing X.").
                * Summarize their financial state simply.

        2.  **Creative Content Generator:**
            * If a user asks, you can generate creative content like a sample personal budget, a script for a video explaining 'inflation', or code snippets for financial calculations.

        3.  **Expert Q&A:**
            * Answer general financial questions like a human expert (e.g., 'What is compound interest?', 'Explain what a 401k is.').

        **Critical Rules:**
        * **Language:** You MUST respond in the user's language. If they write in Spanish, respond in Spanish. If in English, respond in English.
        * **Disclaimer:** Always remind the user that you are an AI assistant for a hackathon and this is an educational simulation, **not real, personalized financial advice**.
        * **Tone:** Friendly, insightful, futuristic, and impressive. You are here to win a prize.
        """

        self.chat = model.startChat(history: [
            ModelContent(role: "user", parts: [ModelContent.Part.text(systemPrompt)]),
            ModelContent(role: "model", parts: [ModelContent.Part.text("Understood. I am SwiftFin-Bot, an advanced AI analyst. I'm ready to demonstrate the power of Gemini and analyze your financial data. To begin, please paste your recent transactions from the app, or ask me a financial question!")])
        ])

        let welcome = "Hello! I'm SwiftFin-Bot, your personal AI financial analyst. To get started, you can ask me a question like 'What is inflation?' or **paste your recent expenses from the 'Expenses' tab** for a personalized analysis!"
        messages.append(ChatMessage(text: contextPrompt + "\n\n" + welcome, isFromUser: false))
    }

    func sendMessage(_ text: String) async {
        guard let chat = chat else {
            print("Error: El chat no está inicializado.")
            return
        }

        messages.append(ChatMessage(text: text, isFromUser: true))
        isLoading = true

        do {
            let response = try await chat.sendMessage(text)
            isLoading = false
            if let botResponse = response.text {
                messages.append(ChatMessage(text: botResponse, isFromUser: false))
            }
        } catch {
            isLoading = false
            messages.append(ChatMessage(text: "An error occurred: \(error.localizedDescription)", isFromUser: false))
        }
    }
}
