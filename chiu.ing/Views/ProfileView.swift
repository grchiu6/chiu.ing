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
            case .posts: return "square.grid.2x2.fill"
            case .liked: return "heart.fill"
            case .saved: return "bookmark.fill"
            }
        }
    }

    private var displayUser: User { user ?? session.currentUser }
    private var isCurrentUser: Bool { displayUser.id == session.currentUser.id }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroBanner
                statsStrip
                bioAndBadges
                mutualConnections
                actionButtons
                sectionTabs
                content
                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 16)
        }
        .background(Theme.Palette.cream.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            if isCurrentUser {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .bold))
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                        .foregroundColor(Theme.Palette.charcoal)
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
                }
                .padding(16)
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

    private var heroBanner: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Theme.Palette.gradientPlayful)
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            AvatarView(user: displayUser, size: 96, showsRing: true)
                .offset(y: 40)
        }
        .padding(.bottom, 44)
        .padding(.top, 8)
    }

    private var statsStrip: some View {
        HStack(spacing: 0) {
            stat(displayUser.postsCount, "Posts")
            Divider().frame(height: 30)
            stat(displayUser.followersCount, "Followers")
            Divider().frame(height: 30)
            stat(displayUser.followingCount, "Following")
        }
        .padding(.vertical, 12)
        .chiuCard()
    }

    private func stat(_ n: Int, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(formatted(n))
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Palette.charcoal)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private func formatted(_ n: Int) -> String {
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        return "\(n)"
    }

    private var bioAndBadges: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(displayUser.displayName)
                .font(Theme.Typography.title)
            Text("@\(displayUser.username) • \(displayUser.city)")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
            if !displayUser.bio.isEmpty {
                Text(displayUser.bio)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Palette.charcoal)
            }
            if !displayUser.badges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(displayUser.badges, id: \.self) { b in
                            Text("⭐️ \(b)")
                                .font(Theme.Typography.tag)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.Palette.gradientPlayful)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                HStack(spacing: 10) {
                    HStack(spacing: -10) {
                        ForEach(mutuals.prefix(3)) { m in
                            AvatarView(user: m, size: 28, showsRing: false)
                                .overlay(Circle().stroke(Theme.Palette.cream, lineWidth: 2))
                        }
                    }
                    Text(mutualText(count: mutuals.count, first: mutuals.first))
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Palette.charcoal.opacity(0.7))
                    Spacer()
                }
                .padding(.vertical, 4)
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
        HStack(spacing: 10) {
            if isCurrentUser {
                capsuleButton("Edit profile", filled: false) { showingSettings = true }
                ShareLink(item: "Follow me on chiu·ing — @\(displayUser.username)") {
                    Text("Share")
                        .font(Theme.Typography.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(Theme.Palette.gradientWarm)
                        .clipShape(Capsule())
                }
            } else {
                let following = session.followedUserIDs.contains(displayUser.id)
                capsuleButton(following ? "Following" : "Follow", filled: !following) {
                    session.toggleFollow(displayUser)
                }
                capsuleButton("Message", filled: false) {}
            }
        }
    }

    @ViewBuilder
    private func capsuleButton(_ title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .foregroundColor(filled ? .white : Theme.Palette.charcoal)
                .background(
                    filled
                    ? AnyView(Theme.Palette.gradientWarm)
                    : AnyView(Color.white)
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Theme.Palette.charcoal.opacity(0.08), lineWidth: 1)
                )
        }
    }

    private var sectionTabs: some View {
        HStack(spacing: 6) {
            ForEach(Section.allCases) { section in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedSection = section }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: section.icon)
                        Text(section.rawValue)
                    }
                    .font(Theme.Typography.caption)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        selectedSection == section
                        ? AnyView(Theme.Palette.gradientWarm)
                        : AnyView(Color.white)
                    )
                    .foregroundColor(selectedSection == section ? .white : Theme.Palette.charcoal)
                    .clipShape(Capsule())
                }
            }
            Spacer()
        }
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
            VStack(spacing: 8) {
                Text(emptyEmoji)
                    .font(.system(size: 54))
                Text(emptyMessage)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
        } else {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                spacing: 8
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

    private var emptyEmoji: String {
        switch selectedSection {
        case .posts: return "📸"; case .liked: return "💗"; case .saved: return "🔖"
        }
    }
    private var emptyMessage: String {
        switch selectedSection {
        case .posts: return "No posts yet — go chew something worth sharing."
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
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .foregroundColor(Theme.Palette.bubblegumPink)
                Text("\(post.likeCount)")
            }
            .font(Theme.Typography.caption)
            .foregroundColor(.white)
            .padding(8)
        }
    }
}
