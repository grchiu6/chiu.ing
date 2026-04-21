import Foundation

struct User: Identifiable, Hashable, Codable {
    let id: UUID
    var username: String
    var displayName: String
    var bio: String
    var avatarEmoji: String
    var followersCount: Int
    var followingCount: Int
    var postsCount: Int
    var badges: [String]
    var city: String

    init(
        id: UUID = UUID(),
        username: String,
        displayName: String,
        bio: String = "",
        avatarEmoji: String = "🍜",
        followersCount: Int = 0,
        followingCount: Int = 0,
        postsCount: Int = 0,
        badges: [String] = [],
        city: String = "Atlanta"
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.bio = bio
        self.avatarEmoji = avatarEmoji
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.postsCount = postsCount
        self.badges = badges
        self.city = city
    }
}
