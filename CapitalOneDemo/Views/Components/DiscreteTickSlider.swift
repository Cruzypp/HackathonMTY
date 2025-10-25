import SwiftUI

/// A discrete slider with tick marks and labels for each item.
/// Bind to an Int index representing the currently selected item.
struct DiscreteTickSlider: View {
    let items: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Slider(
                value: Binding<Double>(
                    get: { Double(selectedIndex) },
                    set: { newVal in selectedIndex = Int(newVal.rounded()) }
                ),
                in: 0...Double(max(0, items.count - 1)),
                step: 1
            )
            .tint(SwiftFinColor.accentBlue)

            GeometryReader { geo in
                let width = max(1, geo.size.width)
                ZStack(alignment: .topLeading) {
                    // Track
                    Capsule()
                        .fill(SwiftFinColor.surfaceAlt)
                        .frame(height: 4)
                        .offset(y: 6)

                    // Ticks + Labels
                    ForEach(items.indices, id: \.self) { idx in
                        let fraction = items.count > 1 ? CGFloat(idx) / CGFloat(items.count - 1) : 0
                        let xPos = fraction * width
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(idx == selectedIndex ? SwiftFinColor.accentBlue : SwiftFinColor.textSecondary.opacity(0.6))
                                .frame(width: 2, height: idx == selectedIndex ? 12 : 8)
                                .offset(y: 0)
                            Text(items[idx])
                                .font(.caption2)
                                .foregroundStyle(idx == selectedIndex ? SwiftFinColor.textPrimary : SwiftFinColor.textSecondary)
                                .fixedSize()
                                .frame(maxWidth: 70)
                                .offset(y: 2)
                        }
                        .frame(width: 0, alignment: .center)
                        .position(x: xPos, y: 16)
                    }
                }
                .frame(height: 36)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let clampedX = min(max(0, value.location.x), width)
                            guard items.count > 1 else { selectedIndex = 0; return }
                            let fraction = clampedX / width
                            let idx = Int((fraction * CGFloat(items.count - 1)).rounded())
                            selectedIndex = min(max(0, idx), items.count - 1)
                        }
                )
            }
            .frame(height: 40)
        }
    }
}

#Preview {
    @Previewable @State var idx = 2
    return VStack(alignment: .leading) {
        DiscreteTickSlider(items: ["Groceries","Transport","Bills","Shopping","Other"], selectedIndex: $idx)
    }
    .padding()
    .preferredColorScheme(.dark)
}
