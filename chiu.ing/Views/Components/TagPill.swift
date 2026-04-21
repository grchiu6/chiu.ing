import SwiftUI

struct TagPill: View {
    let text: String
    var style: Style = .light
    var onTap: (() -> Void)? = nil

    enum Style { case light, dark, solid }

    var body: some View {
        Button {
            onTap?()
        } label: {
            Text("#\(text)")
                .font(Theme.Typography.tag)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(background)
                .foregroundColor(foreground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    private var background: AnyView {
        switch style {
        case .light:
            return AnyView(Theme.Palette.charcoal.opacity(0.08))
        case .dark:
            return AnyView(Color.white.opacity(0.2))
        case .solid:
            return AnyView(Theme.Palette.gradientWarm)
        }
    }

    private var foreground: Color {
        switch style {
        case .light: return Theme.Palette.charcoal
        case .dark, .solid: return .white
        }
    }
}
