import Foundation

enum PostMedia: Hashable, Codable {
    case photo(emoji: String, bgHex: String)
    case video(posterEmoji: String, bgHex: String, durationSeconds: Int)
    case userImage(data: Data, bgHex: String)
    case userVideo(url: URL, bgHex: String)
}

struct Post: Identifiable, Hashable, Codable {
    let id: UUID
    var authorID: UUID
    var restaurantID: UUID
    var caption: String
    var media: PostMedia
    var tags: [String]
    var likeCount: Int
    var saveCount: Int
    var shareCount: Int
    var createdAt: Date
    var friendsWhoLiked: [UUID]

    init(
        id: UUID = UUID(),
        authorID: UUID,
        restaurantID: UUID,
        caption: String,
        media: PostMedia,
        tags: [String] = [],
        likeCount: Int = 0,
        saveCount: Int = 0,
        shareCount: Int = 0,
        createdAt: Date = Date(),
        friendsWhoLiked: [UUID] = []
    ) {
        self.id = id
        self.authorID = authorID
        self.restaurantID = restaurantID
        self.caption = caption
        self.media = media
        self.tags = tags
        self.likeCount = likeCount
        self.saveCount = saveCount
        self.shareCount = shareCount
        self.createdAt = createdAt
        self.friendsWhoLiked = friendsWhoLiked
    }
}

enum FeedHighlight: Identifiable, Hashable {
    case friendsVisited(friends: [User], restaurant: Restaurant)
    case trendingInCircle(post: Post)
    case friendsLoved(posts: [Post], heading: String)
    case suggestedUsers(users: [User])

    var id: String {
        switch self {
        case .friendsVisited(_, let r): return "friendsVisited-\(r.id)"
        case .trendingInCircle(let p): return "trending-\(p.id)"
        case .friendsLoved(_, let heading): return "loved-\(heading)"
        case .suggestedUsers: return "suggested-users"
        }
    }
}
