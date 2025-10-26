import SwiftUI

struct MonthSelectionControl: View {
    @EnvironmentObject var monthSelector: MonthSelector
    
    var body: some View {
        HStack(spacing: 20) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    monthSelector.previousMonth()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [SwiftFinColor.surfaceAlt.opacity(0.8), SwiftFinColor.surface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.15), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SwiftFinColor.textPrimary)
                }
            }
            .buttonStyle(.plain)

            Spacer()
            
            // Etiqueta central con efecto glass premium
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(SwiftFinColor.accentBlue)
                
                Text(monthSelector.currentMonthYear)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(SwiftFinColor.textPrimary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [SwiftFinColor.surfaceAlt.opacity(0.8), SwiftFinColor.surface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.05), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Capsule()
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
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            
            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    monthSelector.nextMonth()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: monthSelector.isCurrentMonth ?
                                    [SwiftFinColor.surfaceAlt.opacity(0.3), SwiftFinColor.surface.opacity(0.3)] :
                                    [SwiftFinColor.surfaceAlt.opacity(0.8), SwiftFinColor.surface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(monthSelector.isCurrentMonth ? 0.05 : 0.15), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(monthSelector.isCurrentMonth ? SwiftFinColor.textSecondary.opacity(0.5) : SwiftFinColor.textPrimary)
                }
            }
            .buttonStyle(.plain)
            .disabled(monthSelector.isCurrentMonth)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
