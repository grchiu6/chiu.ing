import SwiftUI

struct AvatarView: View {
    let user: User
    var size: CGFloat = 44
    var showsRing: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(ringGradient)
                .frame(width: size + (showsRing ? 6 : 0), height: size + (showsRing ? 6 : 0))
                .opacity(showsRing ? 1 : 0)

            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)

            Text(user.avatarEmoji)
                .font(.system(size: size * 0.55))
        }
    }

    private var ringGradient: LinearGradient {
        let hash = abs(user.username.hashValue)
        switch hash % 3 {
        case 0: return Theme.Palette.gradientWarm
        case 1: return Theme.Palette.gradientFresh
        default: return Theme.Palette.gradientPlayful
        }
    }
}
