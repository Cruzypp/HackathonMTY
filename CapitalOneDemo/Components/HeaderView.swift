import SwiftUI

struct Header: View {
    var body: some View {
        HStack(spacing: 12) {
            // Logo con gradiente liquid glass
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [SwiftFinColor.accentBlue.opacity(0.3), SwiftFinColor.accentBlue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "bird.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SwiftFinColor.accentBlue, Color(hex: "#60A5FA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("SwiftFin")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [SwiftFinColor.textPrimary, SwiftFinColor.textPrimary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Spacer()
            
            // Avatar con efecto glass
            Circle()
                .fill(
                    LinearGradient(
                        colors: [SwiftFinColor.surfaceAlt.opacity(0.8), SwiftFinColor.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(SwiftFinColor.textSecondary)
                )
                .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(
            ZStack {
                SwiftFinColor.bgPrimary.opacity(0.95)
                
                // Efecto glass sutil
                LinearGradient(
                    colors: [.white.opacity(0.03), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
    }
}

// MARK: - Previews
struct Header_Previews: PreviewProvider {
    static var previews: some View {
        Header()
            .previewLayout(.sizeThatFits)
            .padding()
            .background(SwiftFinColor.bgPrimary)
            .preferredColorScheme(.dark)
    }
}
