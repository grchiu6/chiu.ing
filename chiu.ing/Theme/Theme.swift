import SwiftUI

// Design system for chiu·ing.
//
// Discipline:
//   – 4 point spacing scale everywhere.
//   – One serif family for headings, one sans family for body.
//   – Single accent. Neutrals do the structural work.
//   – Three corner radii (8 / 12 / 20). Nothing in between.
//   – Shadows are rare and subtle. Borders carry the weight.

enum Theme {

    // MARK: - Palette

    enum Palette {
        // Surfaces
        static let surface          = Color(red: 0.969, green: 0.957, blue: 0.937)   // #F7F4EF warm paper
        static let surfaceElevated  = Color.white
        static let surfaceSunk      = Color(red: 0.945, green: 0.929, blue: 0.902)   // #F1EDE6

        // Structural lines
        static let border           = Color(red: 0.898, green: 0.882, blue: 0.847)   // #E5E1D8
        static let borderStrong     = Color(red: 0.831, green: 0.808, blue: 0.761)   // #D4CEC2

        // Type
        static let ink              = Color(red: 0.086, green: 0.086, blue: 0.090)   // #161617
        static let inkSecondary     = Color(red: 0.325, green: 0.325, blue: 0.329)   // #535354
        static let inkTertiary      = Color(red: 0.576, green: 0.569, blue: 0.549)   // #93918C
        static let inkOnDark        = Color.white

        // Accent — single warm terracotta. Used sparingly for emphasis only.
        static let accent           = Color(red: 0.710, green: 0.302, blue: 0.176)   // #B54D2D
        static let accentSoft       = Color(red: 0.957, green: 0.906, blue: 0.878)   // #F4E7E0
        static let accentInk        = Color(red: 0.541, green: 0.227, blue: 0.133)   // #8A3A22

        // Functional
        static let gold             = Color(red: 0.635, green: 0.482, blue: 0.192)   // ratings only

        // MARK: Back-compat aliases (old theme names → new tokens)
        // Preserved so existing view code compiles while migrating.
        static let charcoal         = ink
        static let cream            = surface
        static let sunsetOrange     = accent
        static let mangoYellow      = gold
        static let bubblegumPink    = accent
        static let skyBlue          = ink
        static let limeGreen        = inkSecondary
        static let eggplant         = ink

        // Gradients kept as aliases but resolve to flat accent so legacy call sites
        // render cleanly. New code should prefer solid `accent`.
        static let gradientWarm = LinearGradient(
            colors: [accent, accent],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let gradientFresh = LinearGradient(
            colors: [surfaceSunk, surfaceSunk],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let gradientPlayful = LinearGradient(
            colors: [accent, accentInk],
            startPoint: .leading, endPoint: .trailing
        )
    }

    // MARK: - Spacing (4pt scale)

    enum Space {
        static let xxs: CGFloat = 4
        static let xs:  CGFloat = 8
        static let s:   CGFloat = 12
        static let m:   CGFloat = 16
        static let l:   CGFloat = 20
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let gutter: CGFloat = 20   // page horizontal padding
        static let section: CGFloat = 28  // vertical gap between sections
    }

    // MARK: - Typography
    //
    // Headings = system serif (New York).
    // Body, labels, captions = system default (SF).
    // Sizes on a consistent ramp; weights are minimal.

    enum Typography {
        static let display     = Font.system(size: 30, weight: .semibold, design: .serif)
        static let title       = Font.system(size: 22, weight: .semibold, design: .serif)
        static let titleSmall  = Font.system(size: 18, weight: .semibold, design: .serif)

        static let headline    = Font.system(size: 16, weight: .semibold, design: .default)
        static let subheadline = Font.system(size: 15, weight: .medium,   design: .default)
        static let body        = Font.system(size: 15, weight: .regular,  design: .default)
        static let label       = Font.system(size: 13, weight: .medium,   design: .default)
        static let caption     = Font.system(size: 13, weight: .regular,  design: .default)
        static let micro       = Font.system(size: 11, weight: .medium,   design: .default)

        // Tracking helpers for labels that need to feel intentional.
        static let eyebrowTracking: CGFloat = 1.4
    }

    // MARK: - Radii & Shadow

    enum Radius {
        static let small: CGFloat  = 8
        static let medium: CGFloat = 12
        static let large: CGFloat  = 20
    }

    enum Shadow {
        static let subtle = (color: Color.black.opacity(0.04), radius: CGFloat(2), y: CGFloat(1))
        static let card   = (color: Color.black.opacity(0.05), radius: CGFloat(10), y: CGFloat(4))
    }

    // MARK: - Legacy aliases

    enum Metrics {
        static let cornerRadius: CGFloat       = Radius.medium
        static let cornerRadiusSmall: CGFloat  = Radius.small
        static let cardShadowOpacity: Double   = 0.05
        static let cardShadowRadius: CGFloat   = 10
    }
}

// MARK: - View modifiers

extension View {
    /// Standard card surface: white, bordered, soft shadow. Used for grouped content.
    func chiuCard() -> some View {
        modifier(ChiuCardStyle())
    }

    /// Inline eyebrow label: small uppercased tracked caption — for "for you", "trending", etc.
    func eyebrowStyle() -> some View {
        self
            .font(Theme.Typography.micro)
            .tracking(Theme.Typography.eyebrowTracking)
            .textCase(.uppercase)
            .foregroundColor(Theme.Palette.inkTertiary)
    }

    /// Legacy pill helper, preserved so existing call sites compile.
    func chiuPillTag(color: Color) -> some View {
        self
            .font(Theme.Typography.micro)
            .padding(.horizontal, Theme.Space.s)
            .padding(.vertical, Theme.Space.xxs)
            .background(Theme.Palette.surfaceSunk)
            .foregroundColor(Theme.Palette.ink)
            .overlay(
                Capsule().stroke(Theme.Palette.border, lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

private struct ChiuCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Palette.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(Theme.Palette.border, lineWidth: 1)
            )
            .shadow(
                color: Theme.Shadow.card.color,
                radius: Theme.Shadow.card.radius,
                x: 0, y: Theme.Shadow.card.y
            )
    }
}

// MARK: - Primary button style

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Space.m)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(isEnabled ? Theme.Palette.ink : Theme.Palette.inkTertiary)
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundColor(Theme.Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Space.m)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Palette.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(Theme.Palette.borderStrong, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
