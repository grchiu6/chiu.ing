import SwiftUI

struct SearchView: View {
    @EnvironmentObject var session: SessionStore
    @State private var query: String = ""
    @State private var scope: Scope = .all
    @State private var presentedRestaurant: Restaurant?
    @State private var presentedUser: User?
    @State private var openingTag: IdentifiedTag?

    enum Scope: String, CaseIterable, Identifiable {
        case all = "All", places = "Places", users = "People", tags = "Tags"
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                searchField
                scopePicker
                if query.isEmpty {
                    discoverContent
                } else {
                    resultsContent
                }
                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Theme.Palette.cream.ignoresSafeArea())
        .sheet(item: $presentedRestaurant) { RestaurantDetailView(restaurant: $0).environmentObject(session) }
        .sheet(item: $presentedUser) { ProfileView(user: $0).environmentObject(session) }
        .fullScreenCover(item: $openingTag) { tag in
            TagFeedContainer(tag: tag.value).environmentObject(session)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Palette.charcoal.opacity(0.5))
            TextField("Search users, places, tags", text: $query)
                .font(Theme.Typography.body)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Palette.charcoal.opacity(0.3))
                }
            }
        }
        .padding(14)
        .chiuCard()
        .padding(.top, 4)
    }

    private var scopePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Scope.allCases) { s in
                    Button {
                        withAnimation(.spring(response: 0.3)) { scope = s }
                    } label: {
                        Text(s.rawValue)
                            .font(Theme.Typography.caption)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                scope == s
                                ? AnyView(Theme.Palette.gradientWarm)
                                : AnyView(Color.white)
                            )
                            .foregroundColor(scope == s ? .white : Theme.Palette.charcoal)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var discoverContent: some View {
        sectionHeader("Trending tags", emoji: "🔥")
        FlowTagStrip(tags: MockData.trendingTags) { tag in
            openingTag = IdentifiedTag(value: tag)
        }

        sectionHeader("Top foodies in your city", emoji: "⭐️")
        VStack(spacing: 10) {
            ForEach(topFoodies) { u in
                Button { presentedUser = u } label: {
                    SuggestedUserRow(user: u)
                }
                .buttonStyle(.plain)
            }
        }

        sectionHeader("Hot spots in \(session.locationFilter.city)", emoji: "📍")
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MockData.restaurants(in: session.locationFilter.city)
                            .sorted { $0.rating > $1.rating }.prefix(6)) { r in
                    Button { presentedRestaurant = r } label: {
                        PlaceMiniCard(restaurant: r)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var resultsContent: some View {
        let lowQ = query.lowercased()
        let matchedUsers = MockData.users.filter {
            $0.username.lowercased().contains(lowQ) ||
            $0.displayName.lowercased().contains(lowQ)
        }
        let matchedPlaces = MockData.restaurants.filter {
            $0.name.lowercased().contains(lowQ) ||
            $0.cuisine.lowercased().contains(lowQ) ||
            $0.neighborhood.lowercased().contains(lowQ) ||
            $0.tags.contains { $0.lowercased().contains(lowQ) }
        }
        let matchedTags = Array(Set(MockData.restaurants.flatMap(\.tags) + MockData.trendingTags))
            .filter { $0.lowercased().contains(lowQ) }
            .sorted()

        if (scope == .all || scope == .users), !matchedUsers.isEmpty {
            sectionHeader("People", emoji: "🧑")
            VStack(spacing: 10) {
                ForEach(matchedUsers) { u in
                    Button { presentedUser = u } label: { SuggestedUserRow(user: u) }
                        .buttonStyle(.plain)
                }
            }
        }

        if (scope == .all || scope == .places), !matchedPlaces.isEmpty {
            sectionHeader("Places", emoji: "🍽️")
            VStack(spacing: 10) {
                ForEach(matchedPlaces) { r in
                    Button { presentedRestaurant = r } label: { PlaceRow(restaurant: r) }
                        .buttonStyle(.plain)
                }
            }
        }

        if (scope == .all || scope == .tags), !matchedTags.isEmpty {
            sectionHeader("Tags", emoji: "🏷️")
            FlowTagStrip(tags: matchedTags) { tag in
                openingTag = IdentifiedTag(value: tag)
            }
        }

        if matchedUsers.isEmpty && matchedPlaces.isEmpty && matchedTags.isEmpty {
            VStack(spacing: 10) {
                Text("🍽️")
                    .font(.system(size: 54))
                Text("No matches for “\(query)”")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    private func sectionHeader(_ title: String, emoji: String) -> some View {
        HStack {
            Text("\(emoji) \(title)")
                .font(Theme.Typography.headline)
            Spacer()
        }
    }

    private var topFoodies: [User] {
        MockData.users
            .filter { $0.id != session.currentUser.id }
            .sorted { $0.followersCount > $1.followersCount }
            .prefix(3)
            .map { $0 }
    }
}

struct FlowTagStrip: View {
    let tags: [String]
    let onTap: (String) -> Void

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { t in
                Button { onTap(t) } label: {
                    TagPill(text: t)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PlaceMiniCard: View {
    let restaurant: Restaurant
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.Palette.gradientFresh)
                    .frame(width: 160, height: 110)
                Text(restaurant.heroEmoji).font(.system(size: 64))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(restaurant.name)
                    .font(Theme.Typography.headline)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Theme.Palette.mangoYellow)
                    Text(String(format: "%.1f", restaurant.rating))
                    Text("• \(restaurant.neighborhood)")
                        .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
                        .lineLimit(1)
                }
                .font(Theme.Typography.caption)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 160)
    }
}

struct PlaceRow: View {
    let restaurant: Restaurant
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.Palette.gradientWarm)
                    .frame(width: 56, height: 56)
                Text(restaurant.heroEmoji).font(.system(size: 28))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.name).font(Theme.Typography.headline)
                Text("\(restaurant.cuisine) • \(restaurant.neighborhood) • \(restaurant.priceLabel)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Theme.Palette.mangoYellow)
                    Text(String(format: "%.1f", restaurant.rating))
                        .fontWeight(.bold)
                }
                .font(Theme.Typography.caption)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Theme.Palette.charcoal.opacity(0.3))
        }
        .padding(12)
        .chiuCard()
    }
}
