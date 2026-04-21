import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var city: String = ""
    @State private var editingTastes: Set<String> = []
    @State private var confirmReset = false

    private let tasteOptions = [
        "brunch", "sushi", "ramen", "tacos", "pizza", "bbq",
        "vegan", "spicy", "pastry", "coffee", "cocktails", "dessert",
        "hotpot", "dumplings", "burgers", "salads"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    LabeledContent("Name") {
                        TextField("Display name", text: $displayName)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Handle") {
                        HStack(spacing: 2) {
                            Text("@").foregroundColor(.secondary)
                            TextField("username", text: $username)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    LabeledContent("City") {
                        TextField("City", text: $city)
                            .multilineTextAlignment(.trailing)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bio").foregroundColor(.secondary)
                        TextField("A vibe, a craving, a signature dish", text: $bio, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }

                Section("Cravings") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], alignment: .leading, spacing: 8) {
                        ForEach(tasteOptions, id: \.self) { t in
                            Button {
                                if editingTastes.contains(t) { editingTastes.remove(t) }
                                else { editingTastes.insert(t) }
                            } label: {
                                Text(t)
                                    .font(Theme.Typography.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        editingTastes.contains(t)
                                        ? AnyView(Theme.Palette.gradientWarm)
                                        : AnyView(Theme.Palette.charcoal.opacity(0.08))
                                    )
                                    .foregroundColor(editingTastes.contains(t) ? .white : Theme.Palette.charcoal)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Location filter") {
                    LabeledContent("Current city", value: session.locationFilter.city)
                    LabeledContent("Radius", value: "\(Int(session.locationFilter.radiusMiles)) mi")
                }

                Section {
                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        Label("Reset onboarding", systemImage: "arrow.counterclockwise")
                    }
                } footer: {
                    Text("This clears your handle, city, and taste picks so you can walk through onboarding again.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "Reset onboarding?",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    session.hasOnboarded = false
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll be sent back through the intro flow the next time the app launches.")
            }
        }
        .onAppear {
            displayName = session.currentUser.displayName
            username = session.currentUser.username
            bio = session.currentUser.bio
            city = session.currentUser.city
            editingTastes = session.tasteTags
        }
    }

    private func save() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        let trimmedCity = city.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty { session.currentUser.displayName = trimmedName }
        if !trimmedUsername.isEmpty { session.currentUser.username = trimmedUsername }
        session.currentUser.bio = bio.trimmingCharacters(in: .whitespaces)
        if !trimmedCity.isEmpty {
            session.currentUser.city = trimmedCity
            session.locationFilter.city = trimmedCity
        }
        session.tasteTags = editingTastes
        dismiss()
    }
}
