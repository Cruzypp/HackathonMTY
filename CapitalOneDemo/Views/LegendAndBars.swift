import SwiftUI

struct LegendSimple: View {
    let items: [(name: String, amount: Double)]
    private let palette: [Color] = [.blue, .green, .orange, .purple, .red, .teal, .yellow]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items.indices, id: \.self) { i in
                HStack {
                    Circle().fill(palette[i % palette.count]).frame(width: 10, height: 10)
                    Text(items[i].name).font(.caption)
                    Spacer()
                    Text(String(format: "$%.0f", items[i].amount))
                        .font(.caption).foregroundStyle(SwiftFinColor.textSecondary)
                }
            }
        }
    }
}

struct CategoryRowBar: View {
    let name: String
    let spent: Double
    let budget: Double

    var over: Bool { spent > budget }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                Spacer()
                Text(String(format: "$%.0f / $%.0f", spent, max(budget, 1)))
                    .foregroundStyle(SwiftFinColor.textSecondary)
                    .font(.caption)
            }
            GeometryReader { geo in
                let w = geo.size.width
                let h: CGFloat = 10
                let maxV = max(spent, budget, 1)
                let spentW = w * spent / maxV
                let budW   = w * budget / maxV

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: h/2).fill(SwiftFinColor.surfaceAlt).frame(height: h)
                    RoundedRectangle(cornerRadius: h/2)
                        .fill(over ? SwiftFinColor.negativeRed : SwiftFinColor.accentBlue)
                        .frame(width: spentW, height: h)
                    Rectangle().fill(Color.white).frame(width: 2, height: h + 8).position(x: budW, y: h/2)
                }
            }
            .frame(height: 14)
        }
    }
}
