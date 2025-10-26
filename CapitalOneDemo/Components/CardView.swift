import SwiftUI

struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .background(
                ZStack {
                    // Fondo azul oscuro Capital One
                    RoundedRectangle(cornerRadius: 16)
                        .fill(SwiftFinColor.surface)
                    
                    // Efecto liquid glass - gradiente sutil
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.08), .clear, .white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), SwiftFinColor.accentBlue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 15, y: 8)
            .shadow(color: SwiftFinColor.capitalOneRed.opacity(0.08), radius: 25, y: 12)
    }
}
