import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var session: SessionStore
    var onFinish: () -> Void

    @State private var stepIndex: Int = 0
    @State private var username: String = ""
    @State private var city: String = "Atlanta"
    @State private var selectedTastes: Set<String> = []

    private let tasteOptions = [
        "brunch", "sushi", "ramen", "tacos", "pizza", "bbq",
        "vegan", "spicy", "pastry", "coffee", "cocktails", "dessert",
        "hotpot", "dumplings", "burgers", "salads"
    ]
    private let cityOptions = ["Atlanta", "New York", "Los Angeles", "Chicago", "Austin", "Seattle", "Miami", "Denver"]

    var body: some View {
        ZStack {
            Theme.Palette.gradientPlayful.ignoresSafeArea()
            VStack(spacing: 20) {
                progressDots
                TabView(selection: $stepIndex) {
                    welcomeStep.tag(0)
                    usernameStep.tag(1)
                    cityStep.tag(2)
                    tasteStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                bottomBar
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 30)
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { i in
                Capsule()
                    .fill(Color.white.opacity(i == stepIndex ? 1 : 0.35))
                    .frame(width: i == stepIndex ? 28 : 10, height: 6)
                    .animation(.spring(response: 0.4), value: stepIndex)
            }
        }
        .padding(.top, 18)
    }

    private var welcomeStep: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("🍜").font(.system(size: 90))
            Text("chiu·ing")
                .font(.system(size: 58, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text("Find food the way your friends find food.")
                .font(Theme.Typography.title)
                .foregroundColor(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
            Spacer()
        }
    }

    private var usernameStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer()
            Text("Pick a handle").font(Theme.Typography.display).foregroundColor(.white)
            Text("This is how friends will find you.")
                .font(Theme.Typography.body).foregroundColor(.white.opacity(0.85))
            HStack {
                Text("@")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Palette.charcoal.opacity(0.4))
                TextField("foodie", text: $username)
                    .font(Theme.Typography.title)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            Spacer(); Spacer()
        }
    }

    private var cityStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer()
            Text("Where do you eat?").font(Theme.Typography.display).foregroundColor(.white)
            Text("We'll show places near you.")
                .font(Theme.Typography.body).foregroundColor(.white.opacity(0.85))
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                    spacing: 10
                ) {
                    ForEach(cityOptions, id: \.self) { c in
                        Button { city = c } label: {
                            Text(c)
                                .font(Theme.Typography.headline)
                                .padding(.vertical, 18)
                                .frame(maxWidth: .infinity)
                                .background(c == city ? Color.white : Color.white.opacity(0.25))
                                .foregroundColor(c == city ? Theme.Palette.sunsetOrange : .white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            }
            Spacer()
        }
    }

    private var tasteStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer(minLength: 0)
            Text("Pick your cravings").font(Theme.Typography.display).foregroundColor(.white)
            Text("We'll tune your feed. Pick 3 or more.")
                .font(Theme.Typography.body).foregroundColor(.white.opacity(0.85))
            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 96), spacing: 8)],
                    alignment: .leading, spacing: 8
                ) {
                    ForEach(tasteOptions, id: \.self) { t in
                        Button {
                            if selectedTastes.contains(t) { selectedTastes.remove(t) }
                            else { selectedTastes.insert(t) }
                        } label: {
                            Text(t)
                                .font(Theme.Typography.caption)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(selectedTastes.contains(t) ? Color.white : Color.white.opacity(0.25))
                                .foregroundColor(selectedTastes.contains(t) ? Theme.Palette.sunsetOrange : .white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var bottomBar: some View {
        HStack {
            if stepIndex > 0 {
                Button("Back") {
                    withAnimation { stepIndex -= 1 }
                }
                .font(Theme.Typography.headline)
                .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
            Button {
                if stepIndex < 3 {
                    withAnimation { stepIndex += 1 }
                } else {
                    finish()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(stepIndex == 3 ? "Let's go" : "Next")
                    Image(systemName: "arrow.right")
                }
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Palette.sunsetOrange)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(Capsule())
                .opacity(canAdvance ? 1 : 0.5)
            }
            .disabled(!canAdvance)
        }
    }

    private var canAdvance: Bool {
        switch stepIndex {
        case 1: return !username.trimmingCharacters(in: .whitespaces).isEmpty
        case 3: return selectedTastes.count >= 3
        default: return true
        }
    }

    private func finish() {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            session.currentUser.username = trimmed
            if session.currentUser.displayName.isEmpty {
                session.currentUser.displayName = trimmed
            }
        }
        session.currentUser.city = city
        session.locationFilter.city = city
        session.tasteTags = selectedTastes
        onFinish()
    }
}
