import SwiftUI

enum AppTab: Hashable {
    case home, scroll, post, profile, search
}

struct RootView: View {
    @State private var selection: AppTab = .scroll
    @State private var showingCreate = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .home: HomeView()
                case .scroll: ScrollFeedView()
                case .post: ScrollFeedView()
                case .search: SearchView()
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
            tabButton(.home, systemImage: "house.fill", label: "Home")
            tabButton(.search, systemImage: "magnifyingglass", label: "Search")

            Button(action: onCreate) {
                ZStack {
                    Circle()
                        .fill(Theme.Palette.gradientWarm)
                        .frame(width: 54, height: 54)
                        .shadow(color: Theme.Palette.sunsetOrange.opacity(0.35),
                                radius: 10, x: 0, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("Create post")

            tabButton(.scroll, systemImage: "play.rectangle.fill", label: "Scroll")
            tabButton(.profile, systemImage: "person.crop.circle.fill", label: "You")
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: -4)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func tabButton(_ tab: AppTab, systemImage: String, label: String) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                Text(label)
                    .font(Theme.Typography.tag)
            }
            .foregroundColor(selection == tab ? Theme.Palette.sunsetOrange : Theme.Palette.charcoal.opacity(0.55))
            .frame(maxWidth: .infinity)
        }
    }
}

