import SwiftUI

enum Theme {
    enum Palette {
        static let sunsetOrange = Color(red: 1.00, green: 0.48, blue: 0.23)
        static let mangoYellow  = Color(red: 1.00, green: 0.78, blue: 0.20)
        static let limeGreen    = Color(red: 0.55, green: 0.85, blue: 0.35)
        static let bubblegumPink = Color(red: 1.00, green: 0.42, blue: 0.65)
        static let skyBlue      = Color(red: 0.33, green: 0.68, blue: 0.98)
        static let eggplant     = Color(red: 0.20, green: 0.13, blue: 0.31)
        static let cream        = Color(red: 1.00, green: 0.97, blue: 0.92)
        static let charcoal     = Color(red: 0.12, green: 0.12, blue: 0.15)

        static let gradientWarm = LinearGradient(
            colors: [sunsetOrange, bubblegumPink],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        static let gradientFresh = LinearGradient(
            colors: [limeGreen, skyBlue],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        static let gradientPlayful = LinearGradient(
            colors: [mangoYellow, sunsetOrange, bubblegumPink],
            startPoint: .leading, endPoint: .trailing
        )
    }

    enum Typography {
        static let display = Font.system(size: 34, weight: .heavy, design: .rounded)
        static let title = Font.system(size: 24, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 15, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
        static let tag = Font.system(size: 11, weight: .bold, design: .rounded)
    }

    enum Metrics {
        static let cornerRadius: CGFloat = 20
        static let cornerRadiusSmall: CGFloat = 12
        static let cardShadowOpacity: Double = 0.12
        static let cardShadowRadius: CGFloat = 14
    }
}

extension View {
    func chiuCard() -> some View {
        self
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(Theme.Metrics.cardShadowOpacity),
                radius: Theme.Metrics.cardShadowRadius,
                x: 0, y: 6
            )
    }

    func chiuPillTag(color: Color) -> some View {
        self
            .font(Theme.Typography.tag)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.18))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}
