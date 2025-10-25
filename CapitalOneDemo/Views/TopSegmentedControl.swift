import SwiftUI

struct TopSegmentedControl: View {
    @Binding var selection: TopTab
    var body: some View {
        HStack(spacing: 8) {
            ForEach(TopTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selection == tab ? .white : SwiftFinColor.textSecondary)
                        .padding(.vertical, 8).padding(.horizontal, 12)
                        .background(selection == tab ? SwiftFinColor.accentBlue : SwiftFinColor.surfaceAlt)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }
}
