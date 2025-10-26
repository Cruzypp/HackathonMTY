import SwiftUI

struct TopSegmentedControl: View {
    @Binding var selection: TopTab
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(TopTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selection == tab ? .white : SwiftFinColor.textSecondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            ZStack {
                                if selection == tab {
                                    // Fondo con gradiente para tab seleccionado
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [SwiftFinColor.accentBlue, Color(hex: "#00559A")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: SwiftFinColor.accentBlue.opacity(0.4), radius: 8, y: 4)
                                    
                                    // Overlay glass effect
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.white.opacity(0.2), .clear],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                } else {
                                    // Fondo glass para tabs no seleccionados
                                    Capsule()
                                        .fill(SwiftFinColor.surfaceAlt.opacity(0.5))
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [.white.opacity(0.1), .clear],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
