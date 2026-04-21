import SwiftUI

enum AppTab: Hashable {
    case home, scroll, post, profile, search
}

struct RootView: View {
    @State private var selection: AppTab = .home
    @State private var showingCreate = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .home:    HomeView()
                case .scroll:  ScrollFeedView()
                case .post:    ScrollFeedView()
                case .search:  SearchView()
                case .profile: ProfileView()
                }
            }
            .ignoresSafeArea(edges: selection == .scroll ? .all : [])

            ChiuTabBar(selection: $selection, onCreate: { showingCreate = true })
        }
        .sheet(isPresented: $showingCreate) {
            CreatePostView()
        }
    }
}

struct ChiuTabBar: View {
    @Binding var selection: AppTab
    var onCreate: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            tabButton(.home,    inactive: "house",          active: "house.fill",          label: "Home")
            tabButton(.search,  inactive: "magnifyingglass", active: "magnifyingglass",    label: "Search")
            createButton
            tabButton(.scroll,  inactive: "play.rectangle", active: "play.rectangle.fill", label: "Feed")
            tabButton(.profile, inactive: "person",         active: "person.fill",         label: "You")
        }
        .padding(.horizontal, Theme.Space.s)
        .padding(.top, Theme.Space.s)
        .padding(.bottom, Theme.Space.l)
        .background(
            Rectangle()
                .fill(Theme.Palette.surfaceElevated)
                .overlay(
                    Rectangle()
                        .fill(Theme.Palette.border)
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var createButton: some View {
        Button(action: {
            Haptics.soft()
            onCreate()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .fill(Theme.Palette.ink)
                    .frame(width: 48, height: 36)
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel("New post")
    }

    @ViewBuilder
    private func tabButton(_ tab: AppTab, inactive: String, active: String, label: String) -> some View {
        let isActive = selection == tab
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isActive ? active : inactive)
                    .font(.system(size: 18, weight: isActive ? .medium : .regular))
                Text(label)
                    .font(Theme.Typography.micro)
            }
            .foregroundColor(isActive ? Theme.Palette.ink : Theme.Palette.inkTertiary)
            .frame(maxWidth: .infinity)
        }
    }
}
