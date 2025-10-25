import SwiftUI

struct Header: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bird.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(SwiftFinColor.accentBlue)
            Text("SwiftFin")
                .font(.system(size: 22, weight: .semibold))
            Spacer()
            Circle()
                .fill(SwiftFinColor.surfaceAlt)
                .frame(width: 28, height: 28)
                .overlay(Image(systemName: "person.fill").font(.footnote))
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 8)
        .background(SwiftFinColor.bgPrimary.opacity(0.95))
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
