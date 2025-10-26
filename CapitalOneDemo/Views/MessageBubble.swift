//MessageBubble.swift

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromUser {
                Spacer(minLength: 60)
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
                    
                    Image(systemName: "waveform.and.person.filled")
                        .font(.system(size: 16))
                        .foregroundStyle(SwiftFinColor.accentBlue)
                }
            }
            

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(.init(message.text))
                    .padding(12)
                    .background(
                        ZStack {
                            // Fondo blanco con leve transparencia
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.9), Color.white.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // Overlay glass sutil
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            // Borde suave
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    // Texto oscuro sobre fondo blanco
                    .foregroundStyle(Color.black)
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: 6,
                        y: 3
                    )
                
                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 280, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer(minLength: 60)
            } else {
                // Avatar del usuario (Capital One Red)
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
