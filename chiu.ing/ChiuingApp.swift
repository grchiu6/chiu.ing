import SwiftUI

@main
struct ChiuingApp: App {
    @StateObject private var session = SessionStore()
    @StateObject private var postStore = PostStore()

    var body: some Scene {
        WindowGroup {
            AppGate()
                .environmentObject(session)
                .environmentObject(postStore)
                .preferredColorScheme(.light)
        }
    }
}

struct AppGate: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        if session.hasOnboarded {
            RootView()
                .transition(.opacity)
        } else {
            OnboardingView(onFinish: {
                withAnimation(.easeInOut(duration: 0.35)) {
                    session.hasOnboarded = true
                }
            })
            .transition(.opacity)
        }
    }
}
