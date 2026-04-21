import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postStore: PostStore
    @Environment(\.dismiss) private var dismiss
    let restaurant: Restaurant

    @State private var position: MapCameraPosition
    @State private var openingTag: IdentifiedTag?

    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: restaurant.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    private var friendsWhoVisited: [User] {
        postStore.posts(atRestaurant: restaurant.id)
            .compactMap { MockData.user(id: $0.authorID) }
            .filter { session.followedUserIDs.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                headingBlock
                actionRow
                tagsRow
                mapSection
                friendsSection
                reviewsSection
                Color.clear.frame(height: 60)
            }
            .padding(.horizontal, 16)
        }
        .background(Theme.Palette.cream.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .padding(14)
        }
        .fullScreenCover(item: $openingTag) { tag in
            TagFeedContainer(tag: tag.value)
                .environmentObject(session)
                .environmentObject(postStore)
        }
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.Palette.gradientWarm)
                .frame(height: 200)
            Text(restaurant.heroEmoji)
                .font(.system(size: 120))
        }
    }

    private var headingBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(restaurant.name)
                .font(Theme.Typography.display)
            HStack(spacing: 8) {
                Text(restaurant.cuisine)
                Text("•")
                Text(restaurant.neighborhood)
                Text("•")
                Text(restaurant.priceLabel)
            }
            .font(Theme.Typography.caption)
            .foregroundColor(Theme.Palette.charcoal.opacity(0.65))
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(Theme.Palette.mangoYellow)
                Text(String(format: "%.1f", restaurant.rating))
                    .fontWeight(.bold)
                Text("• \(postStore.posts(atRestaurant: restaurant.id).count) posts")
                    .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
            }
            .font(Theme.Typography.body)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            actionChip(
                label: session.visitedRestaurantIDs.contains(restaurant.id) ? "Been here ✓" : "Been here",
                icon: "checkmark.seal.fill",
                filled: session.visitedRestaurantIDs.contains(restaurant.id)
            ) {
                session.toggleVisit(restaurant)
            }
            actionChip(label: "Directions", icon: "arrow.triangle.turn.up.right.circle.fill", filled: false) {}
            actionChip(label: "Share", icon: "paperplane.fill", filled: false) {}
        }
    }

    private func actionChip(label: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(Theme.Typography.caption)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                filled
                ? AnyView(Theme.Palette.gradientWarm)
                : AnyView(Color.white)
            )
            .foregroundColor(filled ? .white : Theme.Palette.charcoal)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.Palette.charcoal.opacity(0.08), lineWidth: 1))
        }
    }

    private var tagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(restaurant.tags, id: \.self) { t in
                    TagPill(text: t, onTap: { openingTag = IdentifiedTag(value: t) })
                }
            }
        }
    }

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where to find it")
                .font(Theme.Typography.headline)
            Map(position: $position) {
                Marker(restaurant.name, coordinate: restaurant.coordinate)
                    .tint(Theme.Palette.sunsetOrange)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    @ViewBuilder
    private var friendsSection: some View {
        if !friendsWhoVisited.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Friends who've been")
                    .font(Theme.Typography.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(friendsWhoVisited) { f in
                            VStack(spacing: 6) {
                                AvatarView(user: f, size: 48, showsRing: true)
                                Text("@\(f.username)")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Palette.charcoal.opacity(0.7))
                                    .lineLimit(1)
                            }
                            .frame(width: 70)
                        }
                    }
                }
            }
        }
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick reviews")
                .font(Theme.Typography.headline)
            ForEach(postStore.posts(atRestaurant: restaurant.id)) { post in
                if let author = MockData.user(id: post.authorID) {
                    HStack(alignment: .top, spacing: 10) {
                        AvatarView(user: author, size: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("@\(author.username)")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Palette.charcoal.opacity(0.7))
                            Text(post.caption)
                                .font(Theme.Typography.body)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .chiuCard()
                }
            }
        }
    }
}
