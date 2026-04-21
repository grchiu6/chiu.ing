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
        ZStack(alignment: .top) {
            Theme.Palette.surface.ignoresSafeArea()

            VStack(spacing: Theme.Space.xl) {
                progressBar
                TabView(selection: $stepIndex) {
                    welcomeStep.tag(0)
                    usernameStep.tag(1)
                    cityStep.tag(2)
                    tasteStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                bottomBar
            }
            .padding(.horizontal, Theme.Space.gutter)
            .padding(.top, Theme.Space.xl)
            .padding(.bottom, Theme.Space.xl)
        }
    }

    private var progressBar: some View {
        HStack(spacing: Theme.Space.xs) {
            ForEach(0..<4) { i in
                Rectangle()
                    .fill(i <= stepIndex ? Theme.Palette.ink : Theme.Palette.border)
                    .frame(height: 2)
                    .animation(.easeOut(duration: 0.2), value: stepIndex)
            }
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Spacer()
            Text("Introductions")
                .eyebrowStyle()
            Text("chiu·ing")
                .font(.system(size: 48, weight: .semibold, design: .serif))
                .foregroundColor(Theme.Palette.ink)
            Text("A restaurant network built around the people you actually trust with a dinner recommendation.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var usernameStep: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Spacer()
            Text("Step one").eyebrowStyle()
            Text("Pick a handle")
                .font(Theme.Typography.display)
                .foregroundColor(Theme.Palette.ink)
            Text("This is how friends will find you across the app.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Palette.inkSecondary)

            HStack(spacing: 2) {
                Text("@")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundColor(Theme.Palette.inkTertiary)
                TextField("yourhandle", text: $username)
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundColor(Theme.Palette.ink)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, Theme.Space.m)
            .padding(.vertical, Theme.Space.m)
            .background(Theme.Palette.surfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(Theme.Palette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            Spacer()
            Spacer()
        }
    }

    private var cityStep: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Spacer()
            Text("Step two").eyebrowStyle()
            Text("Where do you eat?")
                .font(Theme.Typography.display)
                .foregroundColor(Theme.Palette.ink)
            Text("We'll seed your feed with spots near you.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Palette.inkSecondary)

            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Theme.Space.xs),
                        GridItem(.flexible(), spacing: Theme.Space.xs)
                    ],
                    spacing: Theme.Space.xs
                ) {
                    ForEach(cityOptions, id: \.self) { c in
                        Button { city = c } label: {
                            Text(c)
                                .font(Theme.Typography.headline)
                                .padding(.vertical, Theme.Space.m)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(c == city ? .white : Theme.Palette.ink)
                                .background(c == city ? Theme.Palette.ink : Theme.Palette.surfaceElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                                        .stroke(
                                            c == city ? Theme.Palette.ink : Theme.Palette.border,
                                            lineWidth: 1
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                        }
                    }
                }
                .padding(.top, Theme.Space.xs)
            }
            Spacer()
        }
    }

    private var tasteStep: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Spacer(minLength: 0)
            Text("Step three").eyebrowStyle()
            Text("What do you crave?")
                .font(Theme.Typography.display)
                .foregroundColor(Theme.Palette.ink)
            Text("Pick three or more. We use these to tune what shows up.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Palette.inkSecondary)

            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100), spacing: Theme.Space.xs)],
                    alignment: .leading, spacing: Theme.Space.xs
                ) {
                    ForEach(tasteOptions, id: \.self) { t in
                        Button {
                            if selectedTastes.contains(t) { selectedTastes.remove(t) }
                            else { selectedTastes.insert(t) }
                        } label: {
                            Text(t)
                                .font(Theme.Typography.label)
                                .padding(.horizontal, Theme.Space.m)
                                .padding(.vertical, Theme.Space.s)
                                .foregroundColor(selectedTastes.contains(t) ? .white : Theme.Palette.ink)
                                .background(selectedTastes.contains(t) ? Theme.Palette.ink : Theme.Palette.surfaceElevated)
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            selectedTastes.contains(t) ? Theme.Palette.ink : Theme.Palette.border,
                                            lineWidth: 1
                                        )
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.top, Theme.Space.xs)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: Theme.Space.s) {
            if stepIndex > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.2)) { stepIndex -= 1 }
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(maxWidth: 120)
            }
            Button {
                if stepIndex < 3 {
                    withAnimation(.easeInOut(duration: 0.2)) { stepIndex += 1 }
                } else {
                    finish()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(stepIndex == 3 ? "Get started" : "Continue")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: canAdvance))
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
