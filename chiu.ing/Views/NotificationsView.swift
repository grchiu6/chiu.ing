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
                LazyVStack(spacing: Theme.Space.s) {
                    if notifications.isEmpty {
                        EmptyNotificationsView(filter: filter)
                            .padding(.top, Theme.Space.xxl)
                    }
                    ForEach(notifications) { n in
                        NotificationRow(
                            notification: n,
                            onOpenUser: { presentedUser = $0 },
                            onOpenRestaurant: { presentedRestaurant = $0 },
                            onOpenPost: { openingPost = $0 }
                        )
                    }
                    Color.clear.frame(height: Theme.Space.xxl)
                }
                .padding(.horizontal, Theme.Space.gutter)
                .padding(.top, Theme.Space.s)
            }
        }
        .background(Theme.Palette.surface.ignoresSafeArea())
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
            VStack(alignment: .leading, spacing: 2) {
                Text("Activity").eyebrowStyle()
                Text("What your circle is up to")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Palette.ink)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Palette.ink)
                    .frame(width: 32, height: 32)
                    .background(Theme.Palette.surfaceElevated)
                    .overlay(Circle().stroke(Theme.Palette.border, lineWidth: 1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, Theme.Space.gutter)
        .padding(.top, Theme.Space.xl)
        .padding(.bottom, Theme.Space.s)
    }

    private var filterBar: some View {
        HStack(spacing: Theme.Space.xs) {
            ForEach(Filter.allCases) { f in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { filter = f }
                } label: {
                    Text(f.rawValue)
                        .font(Theme.Typography.label)
                        .padding(.horizontal, Theme.Space.m)
                        .padding(.vertical, 8)
                        .foregroundColor(filter == f ? .white : Theme.Palette.ink)
                        .background(filter == f ? Theme.Palette.ink : Theme.Palette.surfaceElevated)
                        .overlay(
                            Capsule().stroke(
                                filter == f ? Theme.Palette.ink : Theme.Palette.border,
                                lineWidth: 1
                            )
                        )
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Space.gutter)
        .padding(.bottom, Theme.Space.s)
    }
}

struct EmptyNotificationsView: View {
    let filter: NotificationsView.Filter
    var body: some View {
        VStack(spacing: Theme.Space.xs) {
            Image(systemName: "bell")
                .font(.system(size: 26, weight: .regular))
                .foregroundColor(Theme.Palette.inkTertiary)
                .padding(.bottom, Theme.Space.xs)
            Text("No activity yet")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Palette.ink)
            Text(message)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Palette.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Space.xl)
        .frame(maxWidth: .infinity)
    }

    private var message: String {
        switch filter {
        case .all: return "Likes, follows, and mentions will land here."
        case .mentions: return "When someone @-mentions you, you'll see it here."
        case .friends: return "Follow a few people and their activity will surface here."
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    var onOpenUser: (User) -> Void
    var onOpenRestaurant: (Restaurant) -> Void
    var onOpenPost: (Post) -> Void

    private var actor: User? { MockData.user(id: notification.actorID) }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.s) {
            if let a = actor {
                Button { onOpenUser(a) } label: {
                    AvatarView(user: a, size: 40, showsRing: false)
                }
                .buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 4) {
                attributedText
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(timeString)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.inkTertiary)
                actionArea
                    .padding(.top, 2)
            }
            Spacer()
            if !notification.isRead {
                Circle()
                    .fill(Theme.Palette.accent)
                    .frame(width: 7, height: 7)
                    .padding(.top, 6)
            }
        }
        .padding(Theme.Space.m)
        .chiuCard()
    }

    private var attributedText: Text {
        let name = actor?.displayName ?? "Someone"
        switch notification.kind {
        case .milestone(let text):
            return Text(text).fontWeight(.semibold)
        default:
            return Text(name).fontWeight(.semibold) + Text(" \(actionPhrase)")
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
                    HStack(spacing: Theme.Space.xs) {
                        MediaBackdrop(media: post.media)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                                    .stroke(Theme.Palette.border, lineWidth: 1)
                            )
                        Text(post.caption)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Palette.inkSecondary)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, Theme.Space.xs)
                    .padding(.vertical, Theme.Space.xxs)
                    .background(Theme.Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        case .follow:
            if let a = actor {
                Button { onOpenUser(a) } label: {
                    Text("View profile")
                        .font(Theme.Typography.micro)
                        .padding(.horizontal, Theme.Space.s)
                        .padding(.vertical, 6)
                        .foregroundColor(Theme.Palette.ink)
                        .background(Theme.Palette.surfaceElevated)
                        .overlay(Capsule().stroke(Theme.Palette.border, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        case .friendVisited(let rID):
            if let r = MockData.restaurant(id: rID) {
                Button { onOpenRestaurant(r) } label: {
                    HStack(spacing: 6) {
                        Text(r.heroEmoji).font(.system(size: 14))
                        Text(r.name)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Palette.ink)
                    }
                    .padding(.horizontal, Theme.Space.xs)
                    .padding(.vertical, Theme.Space.xxs)
                    .background(Theme.Palette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                            .stroke(Theme.Palette.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
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
