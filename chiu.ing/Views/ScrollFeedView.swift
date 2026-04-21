import SwiftUI

struct ScrollFeedView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postStore: PostStore
    @Environment(\.dismiss) private var dismiss

    var startPostID: UUID? = nil
    var isPresentedAsSheet: Bool = false
    var postsOverride: [Post]? = nil
    var title: String = "Feed"

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
                        withAnimation(.easeInOut(duration: 0.2)) { feedFilter = .discover }
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

                VStack(spacing: Theme.Space.s) {
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
        .sheet(item: $showingRestaurant) {
            RestaurantDetailView(restaurant: $0).environmentObject(session)
        }
        .sheet(item: $showingCreator) {
            ProfileView(user: $0).environmentObject(session)
        }
    }

    private var feedFilterBar: some View {
        HStack(spacing: Theme.Space.xl) {
            ForEach(FeedFilter.allCases) { f in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { feedFilter = f }
                    Haptics.soft()
                } label: {
                    VStack(spacing: 6) {
                        Text(f.rawValue)
                            .font(Theme.Typography.label)
                            .foregroundColor(.white)
                            .opacity(feedFilter == f ? 1 : 0.55)
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 20, height: 2)
                            .opacity(feedFilter == f ? 1 : 0)
                    }
                }
            }
        }
    }

    private var topOverlay: some View {
        HStack {
            if isPresentedAsSheet {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.35))
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .clipShape(Circle())
                }
            } else {
                Button {
                    showingLocationSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                        Text(session.locationFilter.displayText)
                            .font(Theme.Typography.label)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Space.s)
                    .padding(.vertical, Theme.Space.xs)
                    .background(.black.opacity(0.35))
                    .overlay(Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1))
                    .clipShape(Capsule())
                }
            }
            Spacer()
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundColor(.white)
                .opacity(0.9)
            Spacer()
            Color.clear.frame(width: isPresentedAsSheet ? 36 : 110, height: 30)
        }
        .padding(.horizontal, Theme.Space.m)
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
                            Haptics.soft()
                        }
                    }

                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.6)],
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
                .padding(.horizontal, Theme.Space.m)
                .padding(.bottom, 128)

                swipeHintsOverlay
            }
            .offset(x: dragOffset.width * 0.3)
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
                        withAnimation(.easeOut(duration: 0.22)) {
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
        heartBursts.append(HeartBurst(position: point))
    }

    private var bottomLeftInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Button(action: onTapCreator) {
                HStack(spacing: Theme.Space.s) {
                    AvatarView(user: author, size: 32, showsRing: false)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("@\(author.username)")
                            .font(Theme.Typography.headline)
                            .foregroundColor(.white)
                        Text(author.displayName)
                            .font(Theme.Typography.caption)
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
            }
            Button(action: onTapRestaurant) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 12))
                    Text(place.name)
                        .fontWeight(.medium)
                    Text("·")
                        .foregroundColor(.white.opacity(0.6))
                    Text(place.neighborhood)
                        .foregroundColor(.white.opacity(0.75))
                }
                .font(Theme.Typography.label)
                .foregroundColor(.white)
                .padding(.horizontal, Theme.Space.s)
                .padding(.vertical, 6)
                .background(.black.opacity(0.35))
                .overlay(Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1))
                .clipShape(Capsule())
            }
            Text(post.caption)
                .font(Theme.Typography.body)
                .foregroundColor(.white)
                .lineLimit(3)
                .frame(maxWidth: 280, alignment: .leading)

            if !post.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(post.tags.prefix(3), id: \.self) { t in
                        TagPill(text: t, style: .dark, onTap: { openingTag = IdentifiedTag(value: t) })
                    }
                }
            }
        }
    }

    private var rightActionRail: some View {
        VStack(spacing: Theme.Space.l) {
            actionButton(
                icon: session.likedPostIDs.contains(post.id) ? "heart.fill" : "heart",
                value: post.likeCount + (session.likedPostIDs.contains(post.id) ? 1 : 0),
                highlighted: session.likedPostIDs.contains(post.id),
                action: { session.toggleLike(post) }
            )
            actionButton(
                icon: session.savedPostIDs.contains(post.id) ? "bookmark.fill" : "bookmark",
                value: post.saveCount + (session.savedPostIDs.contains(post.id) ? 1 : 0),
                highlighted: session.savedPostIDs.contains(post.id),
                action: { session.toggleSave(post) }
            )
            shareButton
            actionButton(icon: "ellipsis", value: nil, highlighted: false, action: {})
        }
    }

    private var shareButton: some View {
        ShareLink(item: shareText) {
            VStack(spacing: 4) {
                iconCircle("paperplane", highlighted: false)
                Text(format(post.shareCount))
                    .font(Theme.Typography.micro)
                    .foregroundColor(.white)
            }
        }
    }

    private var shareText: String {
        "@\(author.username) on \(place.name) — \(post.caption)"
    }

    private func actionButton(icon: String, value: Int?, highlighted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                iconCircle(icon, highlighted: highlighted)
                if let value {
                    Text(format(value))
                        .font(Theme.Typography.micro)
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func iconCircle(_ icon: String, highlighted: Bool) -> some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.32))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(highlighted ? Theme.Palette.accent : .white)
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
                hint(text: "Creator", systemImage: "person", align: .trailing)
            }
        }
        .animation(.easeOut(duration: 0.15), value: dragOffset)
        .padding(.horizontal, Theme.Space.xl)
        .allowsHitTesting(false)
    }

    private func hint(text: String, systemImage: String, align: HorizontalAlignment) -> some View {
        VStack(alignment: align, spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .medium))
            Text(text)
                .font(Theme.Typography.label)
        }
        .foregroundColor(.white)
        .padding(Theme.Space.s)
        .background(.black.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
    }
}

struct IdentifiedTag: Identifiable, Hashable {
    var id: String { value }
    let value: String
}

struct EmptyFollowingFeed: View {
    var onSwitch: () -> Void

    var body: some View {
        VStack(spacing: Theme.Space.s) {
            Image(systemName: "person.2")
                .font(.system(size: 30, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, Theme.Space.xs)
            Text("Nothing here yet")
                .font(Theme.Typography.title)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text("Your following feed fills up once you follow a few people.")
                .font(Theme.Typography.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Space.xl)
            Button { onSwitch() } label: {
                Text("Browse Discover")
                    .font(Theme.Typography.label)
                    .foregroundColor(.black)
                    .padding(.horizontal, Theme.Space.l)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            .padding(.top, Theme.Space.xs)
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
            .font(.system(size: 120, weight: .medium))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
            .scaleEffect(0.3 + phase * 0.9)
            .opacity(1 - phase)
            .position(burst.position)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) {
                    phase = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
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
            VStack(spacing: Theme.Space.s) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                Text("Nothing tagged #\(tag) yet")
                    .font(Theme.Typography.title)
                    .foregroundColor(.white)
                Text("Be the first to share one.")
                    .font(Theme.Typography.body)
                    .foregroundColor(.white.opacity(0.7))
                Button("Close") { dismiss() }
                    .font(Theme.Typography.label)
                    .foregroundColor(.black)
                    .padding(.horizontal, Theme.Space.l)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .padding(.top, Theme.Space.s)
            }
        }
    }
}
