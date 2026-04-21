import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postStore: PostStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedEmoji: String = "🍣"
    @State private var backgroundHex: String = "#FF7AAD"
    @State private var caption: String = ""
    @State private var selectedRestaurant: Restaurant?
    @State private var selectedTags: Set<String> = []
    @State private var isVideo: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @State private var pickedImageData: Data?
    @State private var pickedVideoURL: URL?

    private let emojiChoices = ["🍣", "🍜", "🌮", "🥐", "🍕", "🥗", "🍔", "🍱", "🍩", "🧋",
                                "🌶️", "🥟", "🍗", "🍰", "🥞", "🍝", "🍤", "🥘", "🧇", "🍨"]
    private let bgChoices = ["#FF7AAD", "#FFC85C", "#8ED96C", "#5E9EEA",
                             "#FF5733", "#D36AC9", "#F5C26B", "#2E2B47"]
    private let tagChoices = ["brunch", "date night", "cheap eats", "spicy",
                              "late night", "cozy", "group", "solo",
                              "vegan", "sushi", "ramen", "tacos"]

    var body: some View {
        VStack(spacing: 0) {
            handle
            header
            ScrollView {
                VStack(spacing: 18) {
                    mediaPicker
                    mediaBuilder
                    captionField
                    restaurantPicker
                    tagsPicker
                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            postBar
        }
        .background(Theme.Palette.cream.ignoresSafeArea())
    }

    private var handle: some View {
        Capsule()
            .fill(Theme.Palette.charcoal.opacity(0.2))
            .frame(width: 42, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Palette.charcoal.opacity(0.65))
            Spacer()
            Text("Share a bite")
                .font(Theme.Typography.title)
            Spacer()
            Color.clear.frame(width: 48)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var mediaPicker: some View {
        HStack(spacing: 10) {
            mediaToggle(title: "Photo", systemImage: "photo.fill", selected: !isVideo) {
                isVideo = false
                pickedVideoURL = nil
            }
            mediaToggle(title: "Video", systemImage: "video.fill", selected: isVideo) {
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
                Image(systemName: systemImage)
                Text(title)
            }
            .font(Theme.Typography.caption)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(selected
                        ? AnyView(Theme.Palette.gradientWarm)
                        : AnyView(Color.white))
            .foregroundColor(selected ? .white : Theme.Palette.charcoal)
            .clipShape(Capsule())
        }
    }

    private var mediaBuilder: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hex: backgroundHex).opacity(0.95), Color(hex: backgroundHex).opacity(0.55)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 240)
                if let url = pickedVideoURL {
                    VideoPreviewPlayer(url: url)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                } else if let data = pickedImageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                } else {
                    Text(selectedEmoji)
                        .font(.system(size: 140))
                        .shadow(color: .black.opacity(0.15), radius: 14, y: 6)
                }
                if isVideo && pickedVideoURL == nil {
                    VStack {
                        HStack {
                            Spacer()
                            Label("preview", systemImage: "play.fill")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.black.opacity(0.35))
                                .clipShape(Capsule())
                                .padding(12)
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
                                Image(systemName: isVideo ? "video.fill" : "photo.on.rectangle.angled")
                                Text(pickedMediaLabel)
                            }
                            .font(Theme.Typography.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.45))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        if hasPickedMedia {
                            Button {
                                clearPickedMedia()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(8)
                                    .background(.black.opacity(0.45))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
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
            labeledStrip(title: "Dish") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(emojiChoices, id: \.self) { e in
                            Button { selectedEmoji = e } label: {
                                Text(e)
                                    .font(.system(size: 28))
                                    .padding(10)
                                    .frame(width: 50, height: 50)
                                    .background(selectedEmoji == e
                                                ? Theme.Palette.sunsetOrange.opacity(0.15)
                                                : Color.white)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(
                                            selectedEmoji == e ? Theme.Palette.sunsetOrange : .clear,
                                            lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
            }
            labeledStrip(title: "Vibe color") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(bgChoices, id: \.self) { hex in
                            Button { backgroundHex = hex } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle().stroke(
                                            backgroundHex == hex ? Theme.Palette.charcoal : .clear,
                                            lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    private func labeledStrip<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
            content()
        }
        .padding(14)
        .chiuCard()
    }

    private var captionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caption")
                .font(Theme.Typography.headline)
            TextField("Say something tasty…", text: $caption, axis: .vertical)
                .font(Theme.Typography.body)
                .lineLimit(2...5)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var restaurantPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tag a restaurant")
                    .font(Theme.Typography.headline)
                Spacer()
                if selectedRestaurant != nil {
                    Button("Clear") { selectedRestaurant = nil }
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Palette.sunsetOrange)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MockData.restaurants) { r in
                        Button {
                            selectedRestaurant = (selectedRestaurant?.id == r.id) ? nil : r
                        } label: {
                            HStack(spacing: 8) {
                                Text(r.heroEmoji)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.name).font(Theme.Typography.caption).fontWeight(.bold)
                                    Text(r.neighborhood)
                                        .font(Theme.Typography.tag)
                                        .foregroundColor(Theme.Palette.charcoal.opacity(0.55))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(selectedRestaurant?.id == r.id
                                        ? AnyView(Theme.Palette.gradientWarm)
                                        : AnyView(Color.white))
                            .foregroundColor(selectedRestaurant?.id == r.id ? .white : Theme.Palette.charcoal)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }
        }
    }

    private var tagsPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(Theme.Typography.headline)
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

    private var postBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: submit) {
                Text(canPost ? "Post" : "Add a caption and pick a spot")
                    .font(Theme.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canPost ? AnyView(Theme.Palette.gradientWarm)
                                : AnyView(Theme.Palette.charcoal.opacity(0.3)))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(16)
            }
            .disabled(!canPost)
        }
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
        postStore.add(post)
        session.currentUser.postsCount += 1
        dismiss()
    }
}
