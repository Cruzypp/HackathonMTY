import SwiftUI

struct MonthSelectionControl: View {
    @EnvironmentObject var monthSelector: MonthSelector
    
    var body: some View {
        HStack(spacing: 16) {
            // Botón anterior
            Button(action: {
                monthSelector.previousMonth()
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(SwiftFinColor.accentBlue)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(spacing: 4) {
                Text(monthLabel)
                    .font(.headline)
                    .foregroundStyle(Color.white)
                Text(String(yearLabel))
                    .font(.caption)
                    .foregroundStyle(SwiftFinColor.textSecondary)
            }
            .frame(minWidth: 120)
            
            // Botón siguiente
            Button(action: {
                monthSelector.nextMonth()
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(SwiftFinColor.accentBlue)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(monthSelector.isCurrentMonth)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(SwiftFinColor.surface)
        .cornerRadius(12)
        .shadow(color: SwiftFinColor.textSecondary.opacity(0.1), radius: 4)
    }
    
    // Computed properties usando monthSelector.selectedDate
    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: monthSelector.selectedDate)
    }
    
    private var yearLabel: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: monthSelector.selectedDate)
        return components.year ?? 2024
    }
}
