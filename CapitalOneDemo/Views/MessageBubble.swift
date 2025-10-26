import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromUser {
                Spacer(minLength: 60) // Empuja la burbuja del usuario a la derecha
            } else {
                // Avatar del bot con efecto glass
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [SwiftFinColor.accentBlue.opacity(0.3), SwiftFinColor.accentBlue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16))
                        .foregroundStyle(SwiftFinColor.accentBlue)
                }
            }
            

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(
                        ZStack {
                            // Fondo base
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    message.isFromUser ?
                                        LinearGradient(
                                            colors: [SwiftFinColor.accentBlue, Color(hex: "#00559A")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [SwiftFinColor.surface, SwiftFinColor.surfaceAlt],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                            
                            // Efecto glass overlay
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(message.isFromUser ? 0.2 : 0.05), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            // Borde sutil
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .foregroundStyle(message.isFromUser ? .white : SwiftFinColor.textPrimary)
                    .shadow(
                        color: message.isFromUser ? 
                            SwiftFinColor.accentBlue.opacity(0.3) : 
                            .black.opacity(0.1),
                        radius: 8,
                        y: 4
                    )
                
                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(SwiftFinColor.textSecondary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 280, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer(minLength: 60) // Empuja la burbuja del bot a la izquierda
            } else {
                // Avatar del usuario con efecto glass - Capital One Red
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#D92228").opacity(0.3), Color(hex: "#D92228").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#D92228"))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
