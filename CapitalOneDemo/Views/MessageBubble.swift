import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer() // Empuja la burbuja del usuario a la derecha
            }
            
            Text(message.text)
                .padding(12)
                .background(message.isFromUser ? .blue : Color(.systemGray5))
                .foregroundStyle(message.isFromUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .frame(maxWidth: 300, alignment: message.isFromUser ? .trailing : .leading) // Límite de ancho
            
            if !message.isFromUser {
                Spacer() // Empuja la burbuja del bot a la izquierda
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}