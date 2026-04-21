import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postStore: PostStore
    @State private var showingLocationSheet = false
    @State private var showingNotifications = false
    @State private var presentedRestaurant: Restaurant?
    @State private var presentedUser: User?

    private var unreadCount: Int {
        MockData.notifications.filter { !$0.isRead }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                friendsVisitedStrip
                trendingInCircle
                forYouSection
                friendsLoved
                suggestedUsers
                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .refreshable { await refresh() }
        .background(Theme.Palette.cream.ignoresSafeArea())
        .sheet(isPresented: $showingLocationSheet) {
            LocationFilterView()
                .environmentObject(session)
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView().environmentObject(session)
        }
        .sheet(item: $presentedRestaurant) { RestaurantDetailView(restaurant: $0).environmentObject(session) }
        .sheet(item: $presentedUser) { ProfileView(user: $0).environmentObject(session) }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("chiu·ing")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.Palette.gradientWarm)
                Text("your circle's table")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.charcoal.opacity(0.55))
            }
            Spacer()
            Button { showingLocationSheet = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(session.locationFilter.displayText)
                }
                .font(Theme.Typography.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .foregroundColor(Theme.Palette.charcoal)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
            Button { showingNotifications = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .bold))
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                        .foregroundColor(Theme.Palette.charcoal)
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                    if unreadCount > 0 {
                        Text("\(min(unreadCount, 9))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .padding(.horizontal, 3)
                            .background(Theme.Palette.sunsetOrange)
                            .clipShape(Capsule())
                            .offset(x: 4, y: -4)
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    private var forYouSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "For you", emoji: "🎯")
            let posts = personalizedPosts
            if posts.isEmpty {
                Text("Like a few posts and we'll tune this for you.")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.charcoal.opacity(0.55))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
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
                }
            }
        }
    }

    private func refresh() async {
        Haptics.soft()
        try? await Task.sleep(nanoseconds: 600_000_000)
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

    private var friendsVisitedStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Friends recently visited", emoji: "👯")
            let city = session.locationFilter.city
            let places = MockData.restaurants(in: city).prefix(5)
            if places.isEmpty {
                NoLocalContent(city: city)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(places)) { r in
                            FriendsVisitedCard(restaurant: r,
                                               friends: Array(MockData.users.dropFirst().prefix(3)))
                        }
                    }
                }
            }
        }
    }

    private var trendingInCircle: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Trending among your circle", emoji: "🔥")
            if let top = postStore.allPosts.max(by: { $0.likeCount < $1.likeCount }),
               let author = MockData.user(id: top.authorID),
               let place = MockData.restaurant(id: top.restaurantID) {
                TrendingFeatureCard(post: top, author: author, place: place)
            }
        }
    }

    private var friendsLoved: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Places your friends loved", emoji: "💗")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(postStore.allPosts.prefix(5)) { post in
                        if let author = MockData.user(id: post.authorID),
                           let place = MockData.restaurant(id: post.restaurantID) {
                            LovedMiniCard(post: post, author: author, place: place)
                        }
                    }
                }
            }
        }
    }

    private var suggestedUsers: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "New foodies to follow", emoji: "✨")
            VStack(spacing: 10) {
                ForEach(MockData.users.filter { $0.id != session.currentUser.id }
                            .prefix(3)) { user in
                    SuggestedUserRow(user: user)
                }
            }
        }
    }

    private func sectionHeader(title: String, emoji: String) -> some View {
        HStack {
            Text("\(emoji) \(title)")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Palette.charcoal)
            Spacer()
        }
    }
}

struct NoLocalContent: View {
    let city: String
    var body: some View {
        HStack(spacing: 10) {
            Text("🗺️").font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text("No spots seeded in \(city) yet")
                    .font(Theme.Typography.caption)
                    .fontWeight(.bold)
                Text("Try switching your city from the location chip above.")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
            }
            Spacer()
        }
        .padding(12)
        .chiuCard()
    }
}

struct FriendsVisitedCard: View {
    let restaurant: Restaurant
    let friends: [User]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.Palette.gradientFresh)
                    .frame(width: 160, height: 110)
                Text(restaurant.heroEmoji)
                    .font(.system(size: 60))
                    .offset(x: -10, y: 28)
                HStack(spacing: -8) {
                    ForEach(friends.prefix(3)) { f in
                        AvatarView(user: f, size: 22, showsRing: false)
                    }
                }
                .padding(8)
                .background(.white.opacity(0.85))
                .clipShape(Capsule())
                .padding(8)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(restaurant.name)
                    .font(Theme.Typography.headline)
                Text("\(restaurant.neighborhood) • \(restaurant.priceLabel)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 160)
        .padding(.bottom, 6)
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
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius,
                                                style: .continuous))
                HStack(spacing: 10) {
                    AvatarView(user: author, size: 36, showsRing: true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("@\(author.username)")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.white)
                        Text(place.name)
                            .font(Theme.Typography.headline)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.35)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius,
                                                style: .continuous))
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(post.caption)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Palette.charcoal)
                HStack(spacing: 14) {
                    Label("\(post.likeCount)", systemImage: "heart.fill")
                        .foregroundColor(Theme.Palette.bubblegumPink)
                    Label("\(post.saveCount)", systemImage: "bookmark.fill")
                        .foregroundColor(Theme.Palette.skyBlue)
                    Label("\(post.shareCount)", systemImage: "paperplane.fill")
                        .foregroundColor(Theme.Palette.limeGreen)
                }
                .font(Theme.Typography.caption)
            }
            .padding(14)
        }
        .chiuCard()
    }
}

struct LovedMiniCard: View {
    let post: Post
    let author: User
    let place: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MediaBackdrop(media: post.media)
                .frame(width: 140, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(Theme.Typography.headline)
                    .lineLimit(1)
                Text("@\(author.username)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 140)
    }
}

struct SuggestedUserRow: View {
    @EnvironmentObject var session: SessionStore
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(user: user, size: 44, showsRing: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(Theme.Typography.headline)
                Text("@\(user.username) • \(user.followersCount) followers")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
            }
            Spacer()
            Button {
                session.toggleFollow(user)
            } label: {
                Text(session.followedUserIDs.contains(user.id) ? "Following" : "Follow")
                    .font(Theme.Typography.caption)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        session.followedUserIDs.contains(user.id)
                        ? AnyView(Color.white)
                        : AnyView(Theme.Palette.gradientWarm)
                    )
                    .foregroundColor(
                        session.followedUserIDs.contains(user.id)
                        ? Theme.Palette.charcoal : .white
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Theme.Palette.charcoal.opacity(0.1), lineWidth: 1)
                    )
            }
        }
        .padding(12)
        .chiuCard()
    }
}
