import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postStore: PostStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedEmoji: String = "🍣"
    @State private var backgroundHex: String = "#E5E1D8"
    @State private var caption: String = ""
    @State private var selectedRestaurant: Restaurant?
    @State private var selectedTags: Set<String> = []
    @State private var isVideo: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @State private var pickedImageData: Data?
    @State private var pickedVideoURL: URL?
    @State private var isPosting: Bool = false

    private let emojiChoices = ["🍣", "🍜", "🌮", "🥐", "🍕", "🥗", "🍔", "🍱", "🍩", "🧋",
                                "🌶️", "🥟", "🍗", "🍰", "🥞", "🍝", "🍤", "🥘", "🧇", "🍨"]
    // Muted, disciplined tone swatches — warm paper and low-saturation accents.
    private let bgChoices = ["#E5E1D8", "#D6D0C4", "#B8A99A", "#C77B58",
                             "#8A6A4F", "#3F3A33", "#EADCC6", "#A59B8B"]
    private let tagChoices = ["brunch", "date night", "cheap eats", "spicy",
                              "late night", "cozy", "group", "solo",
                              "vegan", "sushi", "ramen", "tacos"]

    var body: some View {
        VStack(spacing: 0) {
            handle
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xl) {
                    mediaPicker
                    mediaBuilder
                    captionField
                    restaurantPicker
                    tagsPicker
                    Color.clear.frame(height: 60)
                }
                .padding(.horizontal, Theme.Space.gutter)
                .padding(.top, Theme.Space.m)
            }
            postBar
        }
        .background(Theme.Palette.surface.ignoresSafeArea())
    }

    // MARK: - Chrome

    private var handle: some View {
        Capsule()
            .fill(Theme.Palette.borderStrong)
            .frame(width: 36, height: 4)
            .padding(.top, Theme.Space.s)
            .padding(.bottom, Theme.Space.xs)
    }

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(Theme.Typography.label)
                .foregroundColor(Theme.Palette.inkSecondary)
            Spacer()
            Text("New post")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Palette.ink)
            Spacer()
            Color.clear.frame(width: 48)
        }
        .padding(.horizontal, Theme.Space.gutter)
        .padding(.bottom, Theme.Space.s)
        .overlay(
            Rectangle()
                .fill(Theme.Palette.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Media

    private var mediaPicker: some View {
        HStack(spacing: Theme.Space.xs) {
            mediaToggle(title: "Photo", systemImage: "photo", selected: !isVideo) {
                isVideo = false
                pickedVideoURL = nil
            }
            mediaToggle(title: "Video", systemImage: "video", selected: isVideo) {
                isVideo = true
                pickedImageData = nil
            }
        }
    }

    private func clearPickedMedia() {
        pickedImageData = nil
        pickedVideoURL = nil
        photoItem = nil
    }

    private func mediaToggle(title: String, systemImage: String, selected: Bool, tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            HStack(spacing: 6) {
                Image(systemName: systemImage).font(.system(size: 13))
                Text(title)
            }
            .font(Theme.Typography.label)
            .padding(.vertical, Theme.Space.s)
            .frame(maxWidth: .infinity)
            .foregroundColor(selected ? .white : Theme.Palette.ink)
            .background(selected ? Theme.Palette.ink : Theme.Palette.surfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .stroke(selected ? Theme.Palette.ink : Theme.Palette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
        }
    }

    private var mediaBuilder: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                    .fill(Color(hex: backgroundHex))
                    .frame(height: 260)
                if let url = pickedVideoURL {
                    VideoPreviewPlayer(url: url)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
                } else if let data = pickedImageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
                } else {
                    Text(selectedEmoji)
                        .font(.system(size: 130))
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                }
                if isVideo && pickedVideoURL == nil {
                    VStack {
                        HStack {
                            Spacer()
                            Label("preview", systemImage: "play.fill")
                                .font(Theme.Typography.micro)
                                .foregroundColor(.white)
                                .padding(.horizontal, Theme.Space.xs)
                                .padding(.vertical, 4)
                                .background(.black.opacity(0.45))
                                .clipShape(Capsule())
                                .padding(Theme.Space.s)
                        }
                        Spacer()
                    }
                }
                VStack {
                    Spacer()
                    HStack {
                        PhotosPicker(
                            selection: $photoItem,
                            matching: isVideo ? .videos : .images,
                            photoLibrary: .shared()
                        ) {
                            HStack(spacing: 6) {
                                Image(systemName: isVideo ? "video" : "photo.on.rectangle.angled")
                                    .font(.system(size: 12))
                                Text(pickedMediaLabel)
                            }
                            .font(Theme.Typography.label)
                            .padding(.horizontal, Theme.Space.s)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.55))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        if hasPickedMedia {
                            Button { clearPickedMedia() } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(7)
                                    .background(.black.opacity(0.55))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                        }
                        Spacer()
                    }
                    .padding(Theme.Space.s)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if isVideo {
                        if let movie = try? await newItem.loadTransferable(type: PickedMovie.self) {
                            await MainActor.run {
                                pickedVideoURL = movie.url
                                pickedImageData = nil
                            }
                        }
                    } else {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            await MainActor.run {
                                pickedImageData = data
                                pickedVideoURL = nil
                            }
                        }
                    }
                }
            }

            labeledStrip(title: "Dish icon") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.xs) {
                        ForEach(emojiChoices, id: \.self) { e in
                            Button { selectedEmoji = e } label: {
                                Text(e)
                                    .font(.system(size: 26))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        selectedEmoji == e
                                        ? Theme.Palette.surfaceSunk
                                        : Theme.Palette.surfaceElevated
                                    )
                                    .overlay(
                                        Circle().stroke(
                                            selectedEmoji == e ? Theme.Palette.ink : Theme.Palette.border,
                                            lineWidth: selectedEmoji == e ? 1.5 : 1
                                        )
                                    )
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }

            labeledStrip(title: "Background tone") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.xs) {
                        ForEach(bgChoices, id: \.self) { hex in
                            Button { backgroundHex = hex } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle().stroke(
                                            backgroundHex == hex ? Theme.Palette.ink : Theme.Palette.border,
                                            lineWidth: backgroundHex == hex ? 1.5 : 1
                                        )
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    private func labeledStrip<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(title).eyebrowStyle()
            content()
        }
        .padding(Theme.Space.m)
        .chiuCard()
    }

    // MARK: - Caption & tagging

    private var captionField: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Caption").eyebrowStyle()
            TextField("What made it worth recommending?", text: $caption, axis: .vertical)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Palette.ink)
                .lineLimit(2...5)
                .padding(Theme.Space.s)
                .background(Theme.Palette.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                        .stroke(Theme.Palette.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        }
    }

    private var restaurantPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack {
                Text("Restaurant").eyebrowStyle()
                Spacer()
                if selectedRestaurant != nil {
                    Button("Clear") { selectedRestaurant = nil }
                        .font(Theme.Typography.label)
                        .foregroundColor(Theme.Palette.accent)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Space.xs) {
                    ForEach(MockData.restaurants) { r in
                        let selected = selectedRestaurant?.id == r.id
                        Button {
                            selectedRestaurant = selected ? nil : r
                        } label: {
                            HStack(spacing: Theme.Space.xs) {
                                Text(r.heroEmoji)
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(r.name)
                                        .font(Theme.Typography.label)
                                    Text(r.neighborhood)
                                        .font(Theme.Typography.micro)
                                        .opacity(0.7)
                                }
                            }
                            .padding(.horizontal, Theme.Space.s)
                            .padding(.vertical, Theme.Space.xs)
                            .foregroundColor(selected ? .white : Theme.Palette.ink)
                            .background(selected ? Theme.Palette.ink : Theme.Palette.surfaceElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                                    .stroke(
                                        selected ? Theme.Palette.ink : Theme.Palette.border,
                                        lineWidth: 1
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous))
                        }
                    }
                }
            }
        }
    }

    private var tagsPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Tags").eyebrowStyle()
            FlowTagStrip(tags: tagChoices) { tag in
                if selectedTags.contains(tag) { selectedTags.remove(tag) }
                else { selectedTags.insert(tag) }
            }
            if !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(selectedTags), id: \.self) { t in
                            TagPill(text: t, style: .solid)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Post bar

    private var postBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.Palette.border)
                .frame(height: 1)
            Button(action: submit) {
                HStack(spacing: 8) {
                    if isPosting {
                        ProgressView()
                            .tint(.white)
                            .controlSize(.small)
                    }
                    Text(buttonLabel)
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: canPost && !isPosting))
            .disabled(!canPost || isPosting)
            .padding(.horizontal, Theme.Space.gutter)
            .padding(.vertical, Theme.Space.m)
        }
    }

    private var buttonLabel: String {
        if isPosting { return "Publishing…" }
        if !canPost { return "Add a caption and a restaurant" }
        return "Publish"
    }

    private var canPost: Bool {
        !caption.trimmingCharacters(in: .whitespaces).isEmpty && selectedRestaurant != nil
    }

    private var pickedMediaLabel: String {
        if pickedVideoURL != nil { return "Change video" }
        if pickedImageData != nil { return "Change photo" }
        return isVideo ? "Pick a video" : "Pick from library"
    }

    private var hasPickedMedia: Bool {
        pickedVideoURL != nil || pickedImageData != nil
    }

    private func submit() {
        guard canPost, let restaurant = selectedRestaurant else { return }
        isPosting = true
        let media: PostMedia
        if let url = pickedVideoURL {
            media = .userVideo(url: url, bgHex: backgroundHex)
        } else if let data = pickedImageData {
            media = .userImage(data: data, bgHex: backgroundHex)
        } else if isVideo {
            media = .video(posterEmoji: selectedEmoji, bgHex: backgroundHex, durationSeconds: 15)
        } else {
            media = .photo(emoji: selectedEmoji, bgHex: backgroundHex)
        }
        let post = Post(
            authorID: session.currentUser.id,
            restaurantID: restaurant.id,
            caption: caption.trimmingCharacters(in: .whitespaces),
            media: media,
            tags: Array(selectedTags),
            likeCount: 0,
            saveCount: 0,
            shareCount: 0,
            createdAt: Date(),
            friendsWhoLiked: []
        )
        // Brief loading so the user sees intent; simulates upload/publish.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            postStore.add(post)
            session.currentUser.postsCount += 1
            isPosting = false
            dismiss()
        }
    }
}
