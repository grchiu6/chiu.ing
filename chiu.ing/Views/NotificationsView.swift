import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var filter: Filter = .all
    @State private var presentedRestaurant: Restaurant?
    @State private var presentedUser: User?
    @State private var openingPost: Post?

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", mentions = "Mentions", friends = "Friends"
        var id: String { rawValue }
    }

    private var notifications: [AppNotification] {
        MockData.notifications
            .sorted { $0.createdAt > $1.createdAt }
            .filter { n in
                switch filter {
                case .all: return true
                case .mentions:
                    if case .mention = n.kind { return true }
                    return false
                case .friends:
                    return session.followedUserIDs.contains(n.actorID)
                }
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            filterBar
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(notifications) { n in
                        NotificationRow(
                            notification: n,
                            onOpenUser: { presentedUser = $0 },
                            onOpenRestaurant: { presentedRestaurant = $0 },
                            onOpenPost: { openingPost = $0 }
                        )
                    }
                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .background(Theme.Palette.cream.ignoresSafeArea())
        .sheet(item: $presentedUser) { ProfileView(user: $0).environmentObject(session) }
        .sheet(item: $presentedRestaurant) { RestaurantDetailView(restaurant: $0).environmentObject(session) }
        .fullScreenCover(item: $openingPost) { post in
            ScrollFeedView(
                startPostID: post.id,
                isPresentedAsSheet: true,
                postsOverride: [post],
                title: "Post"
            )
            .environmentObject(session)
        }
    }

    private var header: some View {
        HStack {
            Text("Activity")
                .font(Theme.Typography.title)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())
                    .foregroundColor(Theme.Palette.charcoal)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(Filter.allCases) { f in
                Button {
                    withAnimation(.spring(response: 0.3)) { filter = f }
                } label: {
                    Text(f.rawValue)
                        .font(Theme.Typography.caption)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            filter == f
                            ? AnyView(Theme.Palette.gradientWarm)
                            : AnyView(Color.white)
                        )
                        .foregroundColor(filter == f ? .white : Theme.Palette.charcoal)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    var onOpenUser: (User) -> Void
    var onOpenRestaurant: (Restaurant) -> Void
    var onOpenPost: (Post) -> Void

    private var actor: User? { MockData.user(id: notification.actorID) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let a = actor {
                Button { onOpenUser(a) } label: {
                    AvatarView(user: a, size: 44, showsRing: true)
                }
                .buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 4) {
                attributedText
                    .font(Theme.Typography.body)
                    .fixedSize(horizontal: false, vertical: true)
                Text(timeString)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.charcoal.opacity(0.5))
                actionArea
            }
            Spacer()
            if !notification.isRead {
                Circle()
                    .fill(Theme.Palette.sunsetOrange)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(12)
        .chiuCard()
    }

    private var attributedText: Text {
        let name = actor?.displayName ?? "Someone"
        let username = actor.map { "@\($0.username)" } ?? ""
        let primary = Text(name).bold() + Text(" ") + Text(actionPhrase)
        switch notification.kind {
        case .milestone(let text): return Text(text).bold()
        default: return primary + Text(" · \(username)").foregroundColor(Theme.Palette.charcoal.opacity(0.55))
        }
    }

    private var actionPhrase: String {
        switch notification.kind {
        case .like: return "liked your post"
        case .follow: return "started following you"
        case .mention: return "mentioned you in a post"
        case .friendVisited(let rID):
            let rName = MockData.restaurant(id: rID)?.name ?? "a spot"
            return "visited \(rName)"
        case .milestone: return ""
        }
    }

    @ViewBuilder
    private var actionArea: some View {
        switch notification.kind {
        case .like(let pID), .mention(let pID):
            if let post = MockData.posts.first(where: { $0.id == pID }) {
                Button {
                    onOpenPost(post)
                } label: {
                    HStack(spacing: 8) {
                        MediaBackdrop(media: post.media)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text(post.caption)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Palette.charcoal.opacity(0.7))
                            .lineLimit(2)
                    }
                    .padding(8)
                    .background(Theme.Palette.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        case .follow:
            if let a = actor {
                Button { onOpenUser(a) } label: {
                    Text("View profile")
                        .font(Theme.Typography.tag)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.Palette.gradientWarm)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        case .friendVisited(let rID):
            if let r = MockData.restaurant(id: rID) {
                Button { onOpenRestaurant(r) } label: {
                    HStack(spacing: 8) {
                        Text(r.heroEmoji)
                        Text(r.name)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Palette.charcoal)
                    }
                    .padding(8)
                    .background(Theme.Palette.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        case .milestone: EmptyView()
        }
    }

    private var timeString: String {
        let elapsed = Date().timeIntervalSince(notification.createdAt)
        if elapsed < 60 { return "just now" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))m ago" }
        if elapsed < 86_400 { return "\(Int(elapsed / 3600))h ago" }
        return "\(Int(elapsed / 86_400))d ago"
    }
}
