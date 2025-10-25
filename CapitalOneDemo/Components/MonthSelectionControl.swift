import SwiftUI

struct MonthSelectionControl: View {
    @EnvironmentObject var monthSelector: MonthSelector
    
    var body: some View {
        HStack {
            Button {
                monthSelector.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Spacer()
            
            Label(monthSelector.currentMonthYear, systemImage: "calendar")
                .font(.subheadline).bold()
                .padding(.vertical, 8).padding(.horizontal, 12)
                .background(SwiftFinColor.surfaceAlt).clipShape(Capsule())
            
            Spacer()

            Button {
                monthSelector.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .disabled(monthSelector.isCurrentMonth)
        }
        .foregroundStyle(SwiftFinColor.textPrimary)
        .padding(.horizontal, 16)
    }
}
