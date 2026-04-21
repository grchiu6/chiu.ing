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
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                searchField
                scopePicker
                if query.isEmpty {
                    discoverContent
                } else {
                    resultsContent
                }
                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, Theme.Space.gutter)
            .padding(.top, Theme.Space.l)
        }
        .background(Theme.Palette.surface.ignoresSafeArea())
        .sheet(item: $presentedRestaurant) {
            RestaurantDetailView(restaurant: $0).environmentObject(session)
        }
        .sheet(item: $presentedUser) {
            ProfileView(user: $0).environmentObject(session)
        }
        .fullScreenCover(item: $openingTag) { tag in
            TagFeedContainer(tag: tag.value).environmentObject(session)
        }
    }

    private var searchField: some View {
        HStack(spacing: Theme.Space.s) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(Theme.Palette.inkTertiary)
            TextField("Search people, places, tags", text: $query)
                .font(Theme.Typography.body)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Palette.inkTertiary)
                }
            }
        }
        .padding(.horizontal, Theme.Space.m)
        .padding(.vertical, 12)
        .background(Theme.Palette.surfaceElevated)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .stroke(Theme.Palette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
    }

    private var scopePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.xs) {
                ForEach(Scope.allCases) { s in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { scope = s }
                    } label: {
                        Text(s.rawValue)
                            .font(Theme.Typography.label)
                            .padding(.horizontal, Theme.Space.m)
                            .padding(.vertical, 8)
                            .foregroundColor(scope == s ? .white : Theme.Palette.ink)
                            .background(scope == s ? Theme.Palette.ink : Theme.Palette.surfaceElevated)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        scope == s ? Theme.Palette.ink : Theme.Palette.border,
                                        lineWidth: 1
                                    )
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var discoverContent: some View {
        sectionHeader(eyebrow: "Explore", title: "Trending tags")
        FlowTagStrip(tags: MockData.trendingTags) { tag in
            openingTag = IdentifiedTag(value: tag)
        }

        sectionHeader(eyebrow: "People", title: "Top foodies in your city")
        VStack(spacing: Theme.Space.s) {
            ForEach(topFoodies) { u in
                Button { presentedUser = u } label: {
                    SuggestedUserRow(user: u)
                }
                .buttonStyle(.plain)
            }
        }

        sectionHeader(eyebrow: "Places", title: "Hot spots in \(session.locationFilter.city)")
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: Theme.Space.s) {
                ForEach(MockData.restaurants(in: session.locationFilter.city)
                            .sorted { $0.rating > $1.rating }.prefix(6)) { r in
                    Button { presentedRestaurant = r } label: {
                        PlaceMiniCard(restaurant: r)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Space.gutter)
        }
        .padding(.horizontal, -Theme.Space.gutter)
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
            sectionHeader(eyebrow: "People", title: "Matching \"\(query)\"")
            VStack(spacing: Theme.Space.s) {
                ForEach(matchedUsers) { u in
                    Button { presentedUser = u } label: { SuggestedUserRow(user: u) }
                        .buttonStyle(.plain)
                }
            }
        }

        if (scope == .all || scope == .places), !matchedPlaces.isEmpty {
            sectionHeader(eyebrow: "Places", title: "Matching \"\(query)\"")
            VStack(spacing: Theme.Space.s) {
                ForEach(matchedPlaces) { r in
                    Button { presentedRestaurant = r } label: { PlaceRow(restaurant: r) }
                        .buttonStyle(.plain)
                }
            }
        }

        if (scope == .all || scope == .tags), !matchedTags.isEmpty {
            sectionHeader(eyebrow: "Tags", title: "Matching \"\(query)\"")
            FlowTagStrip(tags: matchedTags) { tag in
                openingTag = IdentifiedTag(value: tag)
            }
        }

        if matchedUsers.isEmpty && matchedPlaces.isEmpty && matchedTags.isEmpty {
            VStack(spacing: Theme.Space.s) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(Theme.Palette.inkTertiary)
                    .padding(.bottom, Theme.Space.xs)
                Text("No matches for \"\(query)\"")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Palette.ink)
                Text("Try a different handle, city, or tag.")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Palette.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Space.xxxl)
        }
    }

    private func sectionHeader(eyebrow: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Text(eyebrow).eyebrowStyle()
            Text(title)
                .font(Theme.Typography.titleSmall)
                .foregroundColor(Theme.Palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        let columns = [GridItem(.adaptive(minimum: 90), spacing: Theme.Space.xs)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.Space.xs) {
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
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Palette.surfaceSunk)
                    .frame(width: 172, height: 120)
                Text(restaurant.heroEmoji).font(.system(size: 56))
            }
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(Theme.Palette.border, lineWidth: 1)
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(restaurant.name)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Palette.ink)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Palette.gold)
                    Text(String(format: "%.1f", restaurant.rating))
                        .foregroundColor(Theme.Palette.ink)
                    Text("· \(restaurant.neighborhood)")
                        .foregroundColor(Theme.Palette.inkSecondary)
                        .lineLimit(1)
                }
                .font(Theme.Typography.caption)
            }
        }
        .frame(width: 172, alignment: .leading)
    }
}

struct PlaceRow: View {
    let restaurant: Restaurant
    var body: some View {
        HStack(spacing: Theme.Space.s) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .fill(Theme.Palette.surfaceSunk)
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                            .stroke(Theme.Palette.border, lineWidth: 1)
                    )
                Text(restaurant.heroEmoji).font(.system(size: 26))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.name)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Palette.ink)
                Text("\(restaurant.cuisine) · \(restaurant.neighborhood) · \(restaurant.priceLabel)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.inkSecondary)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Palette.gold)
                    Text(String(format: "%.1f", restaurant.rating))
                        .foregroundColor(Theme.Palette.ink)
                }
                .font(Theme.Typography.caption)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.Palette.inkTertiary)
        }
        .padding(Theme.Space.m)
        .chiuCard()
    }
}
