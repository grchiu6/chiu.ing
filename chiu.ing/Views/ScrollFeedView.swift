import SwiftUI

struct ScrollFeedView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postStore: PostStore
    @Environment(\.dismiss) private var dismiss

    var startPostID: UUID? = nil
    var isPresentedAsSheet: Bool = false
    var postsOverride: [Post]? = nil
    var title: String = "Scroll"

    @State private var showingLocationSheet = false
    @State private var showingRestaurant: Restaurant?
    @State private var showingCreator: User?
    @State private var scrollPosition: UUID?
    @State private var feedFilter: FeedFilter = .discover

    enum FeedFilter: String, CaseIterable, Identifiable {
        case following = "Following"
        case discover = "Discover"
        var id: String { rawValue }
    }

    private var posts: [Post] {
        if let postsOverride { return postsOverride }
        let city = session.locationFilter.city
        let base = postStore.allPosts.filter {
            $0.authorID == session.currentUser.id || MockData.isPost($0, in: city)
        }
        switch feedFilter {
        case .discover: return base
        case .following:
            return base.filter {
                session.followedUserIDs.contains($0.authorID) ||
                $0.authorID == session.currentUser.id
            }
        }
    }

    private var showsFilter: Bool {
        postsOverride == nil && !isPresentedAsSheet
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                if posts.isEmpty {
                    EmptyFollowingFeed(onSwitch: {
                        withAnimation(.spring(response: 0.3)) { feedFilter = .discover }
                    })
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(posts) { post in
                                if let author = MockData.user(id: post.authorID),
                                   let place = MockData.restaurant(id: post.restaurantID) {
                                    ScrollPostCard(
                                        post: post,
                                        author: author,
                                        place: place,
                                        onTapRestaurant: { showingRestaurant = place },
                                        onTapCreator: { showingCreator = author }
                                    )
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .id(post.id)
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $scrollPosition)
                    .ignoresSafeArea()
                }

                VStack {
                    topOverlay
                    if showsFilter { feedFilterBar }
                    Spacer()
                }
            }
        }
        .onAppear {
            if scrollPosition == nil {
                scrollPosition = startPostID ?? posts.first?.id
            }
        }
        .sheet(isPresented: $showingLocationSheet) {
            LocationFilterView().environmentObject(session)
        }
        .sheet(item: $showingRestaurant) { restaurant in
            RestaurantDetailView(restaurant: restaurant)
                .environmentObject(session)
        }
        .sheet(item: $showingCreator) { user in
            ProfileView(user: user).environmentObject(session)
        }
    }

    private var feedFilterBar: some View {
        HStack(spacing: 14) {
            ForEach(FeedFilter.allCases) { f in
                Button {
                    withAnimation(.spring(response: 0.3)) { feedFilter = f }
                    Haptics.soft()
                } label: {
                    VStack(spacing: 4) {
                        Text(f.rawValue)
                            .font(Theme.Typography.caption)
                            .fontWeight(feedFilter == f ? .bold : .regular)
                            .foregroundColor(.white)
                            .opacity(feedFilter == f ? 1 : 0.6)
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 22, height: 3)
                            .opacity(feedFilter == f ? 1 : 0)
                    }
                }
            }
        }
        .padding(.top, 10)
    }

    private var topOverlay: some View {
        HStack {
            if isPresentedAsSheet {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.black.opacity(0.35))
                        .clipShape(Circle())
                }
            } else {
                Button {
                    showingLocationSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(session.locationFilter.displayText)
                    }
                    .font(Theme.Typography.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.35))
                    .clipShape(Capsule())
                }
            }
            Spacer()
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundColor(.white)
                .opacity(0.85)
            Spacer()
            Color.clear.frame(width: isPresentedAsSheet ? 40 : 110, height: 30)
        }
        .padding(.horizontal, 16)
        .padding(.top, 52)
    }
}

struct ScrollPostCard: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postStore: PostStore
    let post: Post
    let author: User
    let place: Restaurant
    var onTapRestaurant: () -> Void
    var onTapCreator: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var openingTag: IdentifiedTag?
    @State private var heartBursts: [HeartBurst] = []

    struct HeartBurst: Identifiable, Equatable {
        let id = UUID()
        let position: CGPoint
        let rotation: Double
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MediaBackdrop(media: post.media)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { location in
                        burst(at: location)
                        if !session.likedPostIDs.contains(post.id) {
                            session.toggleLike(post)
                        }
                    }

                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.55)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                ForEach(heartBursts) { burst in
                    HeartBurstView(burst: burst) { completed in
                        heartBursts.removeAll { $0.id == completed }
                    }
                }
                .allowsHitTesting(false)

                HStack(alignment: .bottom) {
                    bottomLeftInfo
                    Spacer()
                    rightActionRail
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 130)

                swipeHintsOverlay
            }
            .offset(x: dragOffset.width * 0.35)
            .gesture(
                DragGesture(minimumDistance: 40)
                    .onChanged { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -80 {
                            onTapRestaurant()
                        } else if value.translation.width > 80 {
                            onTapCreator()
                        }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            dragOffset = .zero
                        }
                    }
            )
            .fullScreenCover(item: $openingTag) { tag in
                TagFeedContainer(tag: tag.value)
                    .environmentObject(session)
                    .environmentObject(postStore)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func burst(at point: CGPoint) {
        let rotation = Double.random(in: -25...25)
        heartBursts.append(HeartBurst(position: point, rotation: rotation))
    }

    private var bottomLeftInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onTapCreator) {
                HStack(spacing: 10) {
                    AvatarView(user: author, size: 36, showsRing: true)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("@\(author.username)")
                            .font(Theme.Typography.headline)
                            .foregroundColor(.white)
                        Text(author.displayName)
                            .font(Theme.Typography.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            Button(action: onTapRestaurant) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                    Text(place.name)
                        .fontWeight(.bold)
                    Text("•")
                    Text(place.neighborhood)
                }
                .font(Theme.Typography.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.black.opacity(0.35))
                .clipShape(Capsule())
            }
            Text(post.caption)
                .font(Theme.Typography.body)
                .foregroundColor(.white)
                .lineLimit(3)
                .frame(maxWidth: 260, alignment: .leading)

            HStack(spacing: 6) {
                ForEach(post.tags, id: \.self) { t in
                    TagPill(text: t, style: .dark, onTap: { openingTag = IdentifiedTag(value: t) })
                }
            }
        }
    }

    private var rightActionRail: some View {
        VStack(spacing: 20) {
            actionButton(
                icon: session.likedPostIDs.contains(post.id) ? "heart.fill" : "heart",
                value: post.likeCount + (session.likedPostIDs.contains(post.id) ? 1 : 0),
                tint: session.likedPostIDs.contains(post.id) ? Theme.Palette.bubblegumPink : .white,
                action: { session.toggleLike(post) }
            )
            actionButton(
                icon: session.savedPostIDs.contains(post.id) ? "bookmark.fill" : "bookmark",
                value: post.saveCount + (session.savedPostIDs.contains(post.id) ? 1 : 0),
                tint: session.savedPostIDs.contains(post.id) ? Theme.Palette.mangoYellow : .white,
                action: { session.toggleSave(post) }
            )
            shareButton
            actionButton(icon: "ellipsis", value: nil, tint: .white, action: {})
        }
    }

    private var shareButton: some View {
        ShareLink(item: shareText) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.3))
                        .frame(width: 48, height: 48)
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(format(post.shareCount))
                    .font(Theme.Typography.caption)
                    .foregroundColor(.white)
            }
        }
    }

    private var shareText: String {
        "Check out @\(author.username)'s take on \(place.name) on chiu·ing — \(post.caption)"
    }

    private func actionButton(icon: String, value: Int?, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.3))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(tint)
                }
                if let value {
                    Text(format(value))
                        .font(Theme.Typography.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func format(_ n: Int) -> String {
        if n >= 1000 {
            return String(format: "%.1fk", Double(n) / 1000.0)
        }
        return "\(n)"
    }

    private var swipeHintsOverlay: some View {
        HStack {
            if dragOffset.width < -20 {
                hint(text: "Restaurant", systemImage: "fork.knife", align: .leading)
                Spacer()
            } else if dragOffset.width > 20 {
                Spacer()
                hint(text: "Creator", systemImage: "person.fill", align: .trailing)
            }
        }
        .animation(.easeOut(duration: 0.15), value: dragOffset)
        .padding(.horizontal, 24)
        .allowsHitTesting(false)
    }

    private func hint(text: String, systemImage: String, align: HorizontalAlignment) -> some View {
        VStack(alignment: align, spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .bold))
            Text(text)
                .font(Theme.Typography.caption)
        }
        .foregroundColor(.white)
        .padding(14)
        .background(.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct IdentifiedTag: Identifiable, Hashable {
    var id: String { value }
    let value: String
}

struct EmptyFollowingFeed: View {
    var onSwitch: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("🌱").font(.system(size: 72))
            Text("Your following feed is empty")
                .font(Theme.Typography.title)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text("Follow a few foodies to curate this view.")
                .font(Theme.Typography.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                onSwitch()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Switch to Discover")
                }
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Palette.sunsetOrange)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct HeartBurstView: View {
    let burst: ScrollPostCard.HeartBurst
    let onComplete: (UUID) -> Void

    @State private var phase: CGFloat = 0

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 140, weight: .black))
            .foregroundStyle(Theme.Palette.gradientWarm)
            .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
            .rotationEffect(.degrees(burst.rotation))
            .scaleEffect(0.2 + phase * 1.1)
            .opacity(1 - phase)
            .position(burst.position)
            .onAppear {
                withAnimation(.easeOut(duration: 0.9)) {
                    phase = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    onComplete(burst.id)
                }
            }
    }
}

struct TagFeedContainer: View {
    @EnvironmentObject var postStore: PostStore
    let tag: String

    private var filteredPosts: [Post] {
        postStore.allPosts.filter { post in
            post.tags.contains(tag) ||
            (MockData.restaurant(id: post.restaurantID)?.tags.contains(tag) ?? false)
        }
    }

    var body: some View {
        if filteredPosts.isEmpty {
            EmptyTagView(tag: tag)
        } else {
            ScrollFeedView(
                startPostID: filteredPosts.first?.id,
                isPresentedAsSheet: true,
                postsOverride: filteredPosts,
                title: "#\(tag)"
            )
        }
    }
}

struct EmptyTagView: View {
    @Environment(\.dismiss) private var dismiss
    let tag: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 14) {
                Text("🍽️").font(.system(size: 64))
                Text("No posts tagged #\(tag)")
                    .font(Theme.Typography.title)
                    .foregroundColor(.white)
                Text("Be the first to share one.")
                    .font(Theme.Typography.body)
                    .foregroundColor(.white.opacity(0.7))
                Button("Close") { dismiss() }
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Palette.sunsetOrange)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .padding(.top, 10)
            }
        }
    }
}
