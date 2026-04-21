import SwiftUI

struct AvatarView: View {
    let user: User
    var size: CGFloat = 44
    var showsRing: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.Palette.surfaceElevated)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            showsRing ? Theme.Palette.ink : Theme.Palette.border,
                            lineWidth: showsRing ? 1.5 : 1
                        )
                )

            Text(user.avatarEmoji)
                .font(.system(size: size * 0.52))
        }
    }
}
