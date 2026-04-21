import SwiftUI

struct MediaBackdrop: View {
    let media: PostMedia

    var body: some View {
        ZStack {
            backgroundGradient
            content
            if case .video = media {
                videoBadge
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch media {
        case .photo(let emoji, _), .video(let emoji, _, _):
            Text(emoji)
                .font(.system(size: 120))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        case .userImage(let data, _):
            if let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
        case .userVideo(let url, _):
            VideoPreviewPlayer(url: url)
        }
    }

    private var videoBadge: some View {
        VStack {
            HStack {
                Spacer()
                Label(durationString, systemImage: "play.fill")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.35))
                    .clipShape(Capsule())
                    .padding(10)
            }
            Spacer()
        }
    }

    private var backgroundGradient: some View {
        let base: Color
        switch media {
        case .photo(_, let hex): base = Color(hex: hex)
        case .video(_, let hex, _): base = Color(hex: hex)
        case .userImage(_, let hex): base = Color(hex: hex)
        case .userVideo(_, let hex): base = Color(hex: hex)
        }
        return LinearGradient(
            colors: [base.opacity(0.95), base.opacity(0.6)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var durationString: String {
        if case let .video(_, _, seconds) = media {
            return "\(seconds)s"
        }
        return ""
    }
}

extension Color {
    init(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") { hex.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
