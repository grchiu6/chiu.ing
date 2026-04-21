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
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                hero
                headingBlock
                actionRow
                if !restaurant.tags.isEmpty { tagsRow }
                mapSection
                if !friendsWhoVisited.isEmpty { friendsSection }
                reviewsSection
                Color.clear.frame(height: Theme.Space.xxl)
            }
            .padding(.horizontal, Theme.Space.gutter)
            .padding(.top, Theme.Space.xl)
        }
        .background(Theme.Palette.surface.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.45))
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .clipShape(Circle())
            }
            .padding(Theme.Space.m)
        }
        .fullScreenCover(item: $openingTag) { tag in
            TagFeedContainer(tag: tag.value)
                .environmentObject(session)
                .environmentObject(postStore)
        }
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .fill(Theme.Palette.surfaceSunk)
                .frame(height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                        .stroke(Theme.Palette.border, lineWidth: 1)
                )
            Text(restaurant.heroEmoji)
                .font(.system(size: 110))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
    }

    private var headingBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(restaurant.cuisine.uppercased())
                .eyebrowStyle()
            Text(restaurant.name)
                .font(Theme.Typography.display)
                .foregroundColor(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Text(restaurant.neighborhood)
                Text("·")
                Text(restaurant.priceLabel)
                Text("·")
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Palette.gold)
                    Text(String(format: "%.1f", restaurant.rating))
                        .foregroundColor(Theme.Palette.ink)
                        .fontWeight(.medium)
                }
                Text("·")
                Text("\(postStore.posts(atRestaurant: restaurant.id).count) posts")
            }
            .font(Theme.Typography.caption)
            .foregroundColor(Theme.Palette.inkSecondary)
        }
    }

    private var actionRow: some View {
        HStack(spacing: Theme.Space.xs) {
            actionChip(
                label: session.visitedRestaurantIDs.contains(restaurant.id) ? "Been here" : "Mark visited",
                icon: session.visitedRestaurantIDs.contains(restaurant.id) ? "checkmark.circle.fill" : "checkmark.circle",
                filled: session.visitedRestaurantIDs.contains(restaurant.id)
            ) {
                session.toggleVisit(restaurant)
                Haptics.soft()
            }
            actionChip(label: "Directions", icon: "arrow.triangle.turn.up.right.circle", filled: false) {}
            actionChip(label: "Share", icon: "paperplane", filled: false) {}
        }
    }

    private func actionChip(label: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13))
                Text(label)
            }
            .font(Theme.Typography.label)
            .padding(.vertical, Theme.Space.s)
            .frame(maxWidth: .infinity)
            .foregroundColor(filled ? .white : Theme.Palette.ink)
            .background(filled ? Theme.Palette.ink : Theme.Palette.surfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .stroke(filled ? Theme.Palette.ink : Theme.Palette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
        }
    }

    private var tagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.xs) {
                ForEach(restaurant.tags, id: \.self) { t in
                    TagPill(text: t, onTap: { openingTag = IdentifiedTag(value: t) })
                }
            }
        }
    }

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Location").eyebrowStyle()
            Map(position: $position) {
                Marker(restaurant.name, coordinate: restaurant.coordinate)
                    .tint(Theme.Palette.accent)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(Theme.Palette.border, lineWidth: 1)
            )
        }
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Who's been here").eyebrowStyle()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Space.m) {
                    ForEach(friendsWhoVisited) { f in
                        VStack(spacing: 6) {
                            AvatarView(user: f, size: 44, showsRing: false)
                            Text("@\(f.username)")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Palette.inkSecondary)
                                .lineLimit(1)
                        }
                        .frame(width: 64)
                    }
                }
            }
        }
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Notes from the feed").eyebrowStyle()
            VStack(spacing: Theme.Space.s) {
                ForEach(postStore.posts(atRestaurant: restaurant.id)) { post in
                    if let author = MockData.user(id: post.authorID) {
                        HStack(alignment: .top, spacing: Theme.Space.s) {
                            AvatarView(user: author, size: 32)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("@\(author.username)")
                                    .font(Theme.Typography.label)
                                    .foregroundColor(Theme.Palette.inkSecondary)
                                Text(post.caption)
                                    .font(Theme.Typography.body)
                                    .foregroundColor(Theme.Palette.ink)
                            }
                            Spacer()
                        }
                        .padding(Theme.Space.m)
                        .chiuCard()
                    }
                }
            }
        }
    }
}
