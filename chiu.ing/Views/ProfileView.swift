import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postStore: PostStore
    var user: User? = nil
    @State private var selectedSection: Section = .posts
    @State private var showingSettings = false
    @State private var openingPost: Post?

    enum Section: String, CaseIterable, Identifiable {
        case posts = "Posts"
        case liked = "Liked"
        case saved = "Saved"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .posts: return "square.grid.2x2"
            case .liked: return "heart"
            case .saved: return "bookmark"
            }
        }
    }

    private var displayUser: User { user ?? session.currentUser }
    private var isCurrentUser: Bool { displayUser.id == session.currentUser.id }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                identityBlock
                statsStrip
                bioAndBadges
                mutualConnections
                actionButtons
                sectionTabs
                content
                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, Theme.Space.gutter)
            .padding(.top, Theme.Space.xl)
        }
        .background(Theme.Palette.surface.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            if isCurrentUser {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Theme.Palette.ink)
                        .frame(width: 36, height: 36)
                        .background(Theme.Palette.surfaceElevated)
                        .overlay(Circle().stroke(Theme.Palette.border, lineWidth: 1))
                        .clipShape(Circle())
                }
                .padding(Theme.Space.m)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView().environmentObject(session)
        }
        .fullScreenCover(item: $openingPost) { post in
            ScrollFeedView(
                startPostID: post.id,
                isPresentedAsSheet: true,
                postsOverride: visiblePosts,
                title: sectionTitle
            )
            .environmentObject(session)
            .environmentObject(postStore)
        }
    }

    private var sectionTitle: String {
        switch selectedSection {
        case .posts: return "\(displayUser.displayName)'s posts"
        case .liked: return "Liked posts"
        case .saved: return "Saved posts"
        }
    }

    // MARK: - Identity

    private var identityBlock: some View {
        HStack(alignment: .center, spacing: Theme.Space.m) {
            AvatarView(user: displayUser, size: 72, showsRing: false)
                .overlay(
                    Circle().stroke(Theme.Palette.border, lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(displayUser.displayName)
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Palette.ink)
                Text("@\(displayUser.username)")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Palette.inkSecondary)
                Text(displayUser.city)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.inkTertiary)
                    .padding(.top, 2)
            }
            Spacer()
        }
    }

    private var statsStrip: some View {
        HStack(spacing: 0) {
            stat(displayUser.postsCount, "Posts")
            divider
            stat(displayUser.followersCount, "Followers")
            divider
            stat(displayUser.followingCount, "Following")
        }
        .padding(.vertical, Theme.Space.m)
        .chiuCard()
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.Palette.border)
            .frame(width: 1, height: 28)
    }

    private func stat(_ n: Int, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(formatted(n))
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundColor(Theme.Palette.ink)
            Text(label)
                .font(Theme.Typography.micro)
                .tracking(Theme.Typography.eyebrowTracking)
                .textCase(.uppercase)
                .foregroundColor(Theme.Palette.inkTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatted(_ n: Int) -> String {
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        return "\(n)"
    }

    private var bioAndBadges: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            if !displayUser.bio.isEmpty {
                Text(displayUser.bio)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Palette.ink)
            }
            if !displayUser.badges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.xs) {
                        ForEach(displayUser.badges, id: \.self) { b in
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal")
                                    .font(.system(size: 10))
                                Text(b)
                            }
                            .font(Theme.Typography.micro)
                            .padding(.horizontal, Theme.Space.s)
                            .padding(.vertical, 6)
                            .foregroundColor(Theme.Palette.ink)
                            .background(Theme.Palette.surfaceElevated)
                            .overlay(
                                Capsule().stroke(Theme.Palette.border, lineWidth: 1)
                            )
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var mutualConnections: some View {
        if !isCurrentUser {
            let mutuals = MockData.users.filter {
                $0.id != session.currentUser.id &&
                $0.id != displayUser.id &&
                session.followedUserIDs.contains($0.id)
            }
            if !mutuals.isEmpty {
                HStack(spacing: Theme.Space.s) {
                    HStack(spacing: -8) {
                        ForEach(mutuals.prefix(3)) { m in
                            AvatarView(user: m, size: 24, showsRing: false)
                                .overlay(Circle().stroke(Theme.Palette.surface, lineWidth: 2))
                        }
                    }
                    Text(mutualText(count: mutuals.count, first: mutuals.first))
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Palette.inkSecondary)
                    Spacer()
                }
            }
        }
    }

    private func mutualText(count: Int, first: User?) -> String {
        guard let first else { return "" }
        if count == 1 { return "Followed by @\(first.username)" }
        if count == 2 { return "Followed by @\(first.username) + 1 other" }
        return "Followed by @\(first.username) + \(count - 1) others"
    }

    private var actionButtons: some View {
        HStack(spacing: Theme.Space.s) {
            if isCurrentUser {
                Button("Edit profile") { showingSettings = true }
                    .buttonStyle(SecondaryButtonStyle())
                ShareLink(item: "Find me on chiu·ing — @\(displayUser.username)") {
                    Text("Share profile")
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                let following = session.followedUserIDs.contains(displayUser.id)
                Button(following ? "Following" : "Follow") {
                    session.toggleFollow(displayUser)
                }
                .buttonStyle(following ? AnyButtonStyle(SecondaryButtonStyle()) : AnyButtonStyle(PrimaryButtonStyle()))
                Button("Message") {}
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var sectionTabs: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedSection = section }
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: section.icon)
                                .font(.system(size: 13, weight: .regular))
                            Text(section.rawValue)
                                .font(Theme.Typography.label)
                        }
                        .foregroundColor(selectedSection == section ? Theme.Palette.ink : Theme.Palette.inkTertiary)
                        Rectangle()
                            .fill(selectedSection == section ? Theme.Palette.ink : Color.clear)
                            .frame(height: 1.5)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(
            Rectangle()
                .fill(Theme.Palette.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var visiblePosts: [Post] {
        switch selectedSection {
        case .posts: return postStore.posts(byAuthor: displayUser.id)
        case .liked: return postStore.allPosts.filter { session.likedPostIDs.contains($0.id) }
        case .saved: return postStore.allPosts.filter { session.savedPostIDs.contains($0.id) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if visiblePosts.isEmpty {
            VStack(spacing: Theme.Space.xs) {
                Image(systemName: emptyIcon)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(Theme.Palette.inkTertiary)
                    .padding(.bottom, Theme.Space.xs)
                Text(emptyTitle)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Palette.ink)
                Text(emptyMessage)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Palette.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, Theme.Space.xxxl)
            .frame(maxWidth: .infinity)
        } else {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Theme.Space.xs),
                    GridItem(.flexible(), spacing: Theme.Space.xs)
                ],
                spacing: Theme.Space.xs
            ) {
                ForEach(visiblePosts) { post in
                    Button { openingPost = post } label: {
                        ProfileGridTile(post: post)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyIcon: String {
        switch selectedSection {
        case .posts: return "camera"
        case .liked: return "heart"
        case .saved: return "bookmark"
        }
    }
    private var emptyTitle: String {
        switch selectedSection {
        case .posts: return "No posts yet"
        case .liked: return "Nothing liked yet"
        case .saved: return "Nothing saved yet"
        }
    }
    private var emptyMessage: String {
        switch selectedSection {
        case .posts: return "Share a meal worth remembering."
        case .liked: return "Posts you love will live here."
        case .saved: return "Save places to find them later."
        }
    }
}

struct ProfileGridTile: View {
    let post: Post
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MediaBackdrop(media: post.media)
                .aspectRatio(3 / 4, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                        .stroke(Theme.Palette.border, lineWidth: 1)
                )
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                Text(formatted(post.likeCount))
            }
            .font(Theme.Typography.micro)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.45))
            .clipShape(Capsule())
            .padding(8)
        }
    }

    private func formatted(_ n: Int) -> String {
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        return "\(n)"
    }
}

// MARK: - Type-erased button style helper

struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { config in AnyView(style.makeBody(configuration: config)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}
