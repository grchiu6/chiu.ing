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
                .font(Theme.Typography.micro)
                .padding(.horizontal, Theme.Space.s)
                .padding(.vertical, 6)
                .background(background)
                .foregroundColor(foreground)
                .overlay(
                    Capsule().stroke(strokeColor, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    private var background: Color {
        switch style {
        case .light: return Theme.Palette.surfaceElevated
        case .dark:  return Color.white.opacity(0.14)
        case .solid: return Theme.Palette.ink
        }
    }

    private var foreground: Color {
        switch style {
        case .light: return Theme.Palette.ink
        case .dark:  return .white
        case .solid: return .white
        }
    }

    private var strokeColor: Color {
        switch style {
        case .light: return Theme.Palette.border
        case .dark:  return Color.white.opacity(0.28)
        case .solid: return Theme.Palette.ink
        }
    }
}
