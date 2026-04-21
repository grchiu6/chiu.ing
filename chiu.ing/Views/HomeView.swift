import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postStore: PostStore
    @State private var showingLocationSheet = false
    @State private var showingNotifications = false
    @State private var presentedRestaurant: Restaurant?
    @State private var presentedUser: User?
    @State private var isRefreshing = false

    private var unreadCount: Int {
        MockData.notifications.filter { !$0.isRead }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.section) {
                header
                friendsVisitedStrip
                trendingInCircle
                forYouSection
                friendsLoved
                suggestedUsers
                Color.clear.frame(height: 96)
            }
            .padding(.horizontal, Theme.Space.gutter)
            .padding(.top, Theme.Space.m)
        }
        .refreshable { await refresh() }
        .background(Theme.Palette.surface.ignoresSafeArea())
        .sheet(isPresented: $showingLocationSheet) {
            LocationFilterView().environmentObject(session)
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView().environmentObject(session)
        }
        .sheet(item: $presentedRestaurant) {
            RestaurantDetailView(restaurant: $0).environmentObject(session)
        }
        .sheet(item: $presentedUser) {
            ProfileView(user: $0).environmentObject(session)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: Theme.Space.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text("chiu·ing")
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.Palette.ink)
                Button { showingLocationSheet = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 11, weight: .regular))
                        Text(session.locationFilter.displayText)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.inkSecondary)
                }
            }
            Spacer()
            Button { showingNotifications = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 16, weight: .regular))
                        .frame(width: 36, height: 36)
                        .foregroundColor(Theme.Palette.ink)
                        .overlay(
                            Circle().stroke(Theme.Palette.border, lineWidth: 1)
                        )
                    if unreadCount > 0 {
                        Circle()
                            .fill(Theme.Palette.accent)
                            .frame(width: 7, height: 7)
                            .offset(x: -4, y: 4)
                    }
                }
            }
            .accessibilityLabel("Activity")
        }
    }

    // MARK: - Sections

    private var friendsVisitedStrip: some View {
        section(eyebrow: "Your circle", title: "Recently visited") {
            let city = session.locationFilter.city
            let places = Array(MockData.restaurants(in: city).prefix(5))
            if places.isEmpty {
                NoLocalContent(city: city)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.s) {
                        ForEach(places) { r in
                            Button {
                                presentedRestaurant = r
                            } label: {
                                FriendsVisitedCard(
                                    restaurant: r,
                                    friends: Array(MockData.users.dropFirst().prefix(3))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Theme.Space.gutter)
                }
                .padding(.horizontal, -Theme.Space.gutter)
            }
        }
    }

    private var trendingInCircle: some View {
        section(eyebrow: "Trending", title: "Most discussed this week") {
            if let top = postStore.allPosts.max(by: { $0.likeCount < $1.likeCount }),
               let author = MockData.user(id: top.authorID),
               let place = MockData.restaurant(id: top.restaurantID) {
                Button {
                    presentedRestaurant = place
                } label: {
                    TrendingFeatureCard(post: top, author: author, place: place)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var forYouSection: some View {
        section(eyebrow: "For you", title: "Tuned to what you save") {
            let posts = personalizedPosts
            if posts.isEmpty {
                Text("Like a few posts and we'll start tuning this list.")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Palette.inkSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Theme.Space.s) {
                        ForEach(posts) { post in
                            if let author = MockData.user(id: post.authorID),
                               let place = MockData.restaurant(id: post.restaurantID) {
                                Button {
                                    presentedRestaurant = place
                                } label: {
                                    LovedMiniCard(post: post, author: author, place: place)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Space.gutter)
                }
                .padding(.horizontal, -Theme.Space.gutter)
            }
        }
    }

    private var friendsLoved: some View {
        section(eyebrow: "Loved", title: "Places your friends returned to") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: Theme.Space.s) {
                    ForEach(postStore.allPosts.prefix(5)) { post in
                        if let author = MockData.user(id: post.authorID),
                           let place = MockData.restaurant(id: post.restaurantID) {
                            LovedMiniCard(post: post, author: author, place: place)
                        }
                    }
                }
                .padding(.horizontal, Theme.Space.gutter)
            }
            .padding(.horizontal, -Theme.Space.gutter)
        }
    }

    private var suggestedUsers: some View {
        section(eyebrow: "Follow", title: "New voices in your city") {
            VStack(spacing: Theme.Space.s) {
                ForEach(MockData.users
                    .filter { $0.id != session.currentUser.id }
                    .prefix(3)) { user in
                    SuggestedUserRow(user: user)
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section<Content: View>(
        eyebrow: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(eyebrow).eyebrowStyle()
                Text(title)
                    .font(Theme.Typography.titleSmall)
                    .foregroundColor(Theme.Palette.ink)
            }
            content()
        }
    }

    private func refresh() async {
        isRefreshing = true
        Haptics.soft()
        try? await Task.sleep(nanoseconds: 700_000_000)
        isRefreshing = false
    }

    private var personalizedPosts: [Post] {
        let followed = session.followedUserIDs
        let tastes = session.tasteTags
        return postStore.allPosts
            .map { post -> (Post, Int) in
                var score = 0
                if followed.contains(post.authorID) { score += 3 }
                if session.likedPostIDs.contains(post.id) { score += 2 }
                if !post.friendsWhoLiked.isEmpty { score += post.friendsWhoLiked.count }
                score += min(post.likeCount / 200, 5)
                let tagOverlap = post.tags.filter { tastes.contains($0) }.count
                score += tagOverlap * 2
                if let r = MockData.restaurant(id: post.restaurantID) {
                    score += r.tags.filter { tastes.contains($0) }.count
                }
                return (post, score)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0.0 }
    }
}

// MARK: - Subviews

struct NoLocalContent: View {
    let city: String
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text("No spots yet in \(city)")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Palette.ink)
            Text("Switch your city from the location selector above.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.m)
        .chiuCard()
    }
}

struct FriendsVisitedCard: View {
    let restaurant: Restaurant
    let friends: [User]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Palette.surfaceSunk)
                    .frame(width: 180, height: 120)
                    .overlay(
                        Text(restaurant.heroEmoji)
                            .font(.system(size: 56))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                            .stroke(Theme.Palette.border, lineWidth: 1)
                    )
                HStack(spacing: -6) {
                    ForEach(friends.prefix(3)) { f in
                        AvatarView(user: f, size: 22, showsRing: false)
                    }
                }
                .padding(6)
                .background(Theme.Palette.surfaceElevated)
                .overlay(
                    Capsule().stroke(Theme.Palette.border, lineWidth: 1)
                )
                .clipShape(Capsule())
                .padding(Theme.Space.xs)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(restaurant.name)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Palette.ink)
                    .lineLimit(1)
                Text("\(restaurant.neighborhood) · \(restaurant.priceLabel)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.inkSecondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 180, alignment: .leading)
    }
}

struct TrendingFeatureCard: View {
    let post: Post
    let author: User
    let place: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                MediaBackdrop(media: post.media)
                    .frame(height: 220)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: Theme.Radius.medium,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: Theme.Radius.medium,
                            style: .continuous
                        )
                    )
                HStack(spacing: Theme.Space.s) {
                    AvatarView(user: author, size: 32, showsRing: false)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("@\(author.username)")
                            .font(Theme.Typography.micro)
                            .foregroundColor(.white.opacity(0.85))
                        Text(place.name)
                            .font(Theme.Typography.headline)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(Theme.Space.m)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }

            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text(post.caption)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Palette.ink)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                HStack(spacing: Theme.Space.m) {
                    metaLabel(systemImage: "heart", value: post.likeCount)
                    metaLabel(systemImage: "bookmark", value: post.saveCount)
                    metaLabel(systemImage: "paperplane", value: post.shareCount)
                }
                .foregroundColor(Theme.Palette.inkSecondary)
            }
            .padding(Theme.Space.m)
        }
        .background(Theme.Palette.surfaceElevated)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .stroke(Theme.Palette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
    }

    private func metaLabel(systemImage: String, value: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 12))
            Text(formatted(value))
                .font(Theme.Typography.label)
        }
    }

    private func formatted(_ n: Int) -> String {
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        return "\(n)"
    }
}

struct LovedMiniCard: View {
    let post: Post
    let author: User
    let place: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            MediaBackdrop(media: post.media)
                .frame(width: 156, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                        .stroke(Theme.Palette.border, lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Palette.ink)
                    .lineLimit(1)
                Text("@\(author.username)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.inkSecondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 156, alignment: .leading)
    }
}

struct SuggestedUserRow: View {
    @EnvironmentObject var session: SessionStore
    let user: User

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            AvatarView(user: user, size: 44, showsRing: false)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Palette.ink)
                Text("@\(user.username) · \(formattedFollowers) followers")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.inkSecondary)
            }
            Spacer()
            Button {
                session.toggleFollow(user)
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(Theme.Typography.label)
                    .frame(minWidth: 84)
                    .padding(.horizontal, Theme.Space.s)
                    .padding(.vertical, Theme.Space.xs)
                    .foregroundColor(isFollowing ? Theme.Palette.ink : .white)
                    .background(isFollowing ? Theme.Palette.surfaceElevated : Theme.Palette.ink)
                    .overlay(
                        Capsule()
                            .stroke(
                                isFollowing ? Theme.Palette.border : Theme.Palette.ink,
                                lineWidth: 1
                            )
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(Theme.Space.m)
        .chiuCard()
    }

    private var isFollowing: Bool {
        session.followedUserIDs.contains(user.id)
    }

    private var formattedFollowers: String {
        if user.followersCount >= 1000 {
            return String(format: "%.1fk", Double(user.followersCount) / 1000.0)
        }
        return "\(user.followersCount)"
    }
}
