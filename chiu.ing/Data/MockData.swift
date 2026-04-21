import Foundation

enum MockData {
    static let currentUser = User(
        username: "graceeats",
        displayName: "Grace 🍣",
        bio: "Brunching my way through the south. Atlanta based.",
        avatarEmoji: "🧋",
        followersCount: 1240,
        followingCount: 318,
        postsCount: 47,
        badges: ["Top foodie in ATL", "Early adopter"],
        city: "Atlanta"
    )

    static let users: [User] = [
        currentUser,
        User(username: "milotaste", displayName: "Milo", bio: "Tacos first, always.", avatarEmoji: "🌮",
             followersCount: 9800, followingCount: 210, postsCount: 132,
             badges: ["Taco scout"], city: "Atlanta"),
        User(username: "kiwi.bites", displayName: "Kiwi", bio: "Vegan but never boring.", avatarEmoji: "🥝",
             followersCount: 540, followingCount: 412, postsCount: 23,
             badges: [], city: "Atlanta"),
        User(username: "hotpotjoy", displayName: "Joy", bio: "On a hotpot pilgrimage.", avatarEmoji: "🍲",
             followersCount: 3200, followingCount: 188, postsCount: 78,
             badges: ["Hotpot hunter"], city: "Atlanta"),
        User(username: "breadfiend", displayName: "Theo", bio: "Carbs = therapy.", avatarEmoji: "🥐",
             followersCount: 412, followingCount: 502, postsCount: 15,
             badges: [], city: "Atlanta"),
        User(username: "slurplord", displayName: "Ren", bio: "Ramen reviews & chaos.", avatarEmoji: "🍜",
             followersCount: 15_600, followingCount: 90, postsCount: 201,
             badges: ["Top foodie in ATL"], city: "Atlanta")
    ]

    static let restaurants: [Restaurant] = [
        Restaurant(id: UUID(), name: "Little Spicy", cuisine: "Sichuan", neighborhood: "Buford Hwy",
                   city: "Atlanta", priceLevel: 2, rating: 4.6,
                   tags: ["spicy", "late night", "group"], heroEmoji: "🌶️",
                   latitude: 33.8762, longitude: -84.3324),
        Restaurant(id: UUID(), name: "Biscuit Baby", cuisine: "Southern", neighborhood: "Old Fourth Ward",
                   city: "Atlanta", priceLevel: 2, rating: 4.4,
                   tags: ["brunch", "cozy", "date night"], heroEmoji: "🥞",
                   latitude: 33.7637, longitude: -84.3697),
        Restaurant(id: UUID(), name: "Maki Maki", cuisine: "Japanese", neighborhood: "Midtown",
                   city: "Atlanta", priceLevel: 3, rating: 4.8,
                   tags: ["sushi", "date night", "pricey"], heroEmoji: "🍣",
                   latitude: 33.7826, longitude: -84.3832),
        Restaurant(id: UUID(), name: "Verde Kitchen", cuisine: "Mexican", neighborhood: "Decatur",
                   city: "Atlanta", priceLevel: 1, rating: 4.5,
                   tags: ["tacos", "cheap eats", "casual"], heroEmoji: "🌮",
                   latitude: 33.7748, longitude: -84.2963),
        Restaurant(id: UUID(), name: "Plantiful", cuisine: "Vegan", neighborhood: "Virginia-Highland",
                   city: "Atlanta", priceLevel: 2, rating: 4.3,
                   tags: ["vegan", "healthy", "brunch"], heroEmoji: "🥗",
                   latitude: 33.7833, longitude: -84.3534),
        Restaurant(id: UUID(), name: "Dough Hive", cuisine: "Bakery", neighborhood: "Inman Park",
                   city: "Atlanta", priceLevel: 1, rating: 4.9,
                   tags: ["pastry", "coffee", "cozy"], heroEmoji: "🥐",
                   latitude: 33.7574, longitude: -84.3522),
        Restaurant(id: UUID(), name: "Broth & Co.", cuisine: "Ramen", neighborhood: "West Midtown",
                   city: "Atlanta", priceLevel: 2, rating: 4.7,
                   tags: ["ramen", "rainy day", "solo"], heroEmoji: "🍜",
                   latitude: 33.7902, longitude: -84.4132),
        Restaurant(id: UUID(), name: "Nori & Fog", cuisine: "Japanese", neighborhood: "SoHo",
                   city: "New York", priceLevel: 3, rating: 4.7,
                   tags: ["sushi", "date night", "pricey"], heroEmoji: "🍱",
                   latitude: 40.7233, longitude: -74.0023),
        Restaurant(id: UUID(), name: "Little Havana", cuisine: "Cuban", neighborhood: "East Village",
                   city: "New York", priceLevel: 2, rating: 4.4,
                   tags: ["casual", "late night", "group"], heroEmoji: "🥘",
                   latitude: 40.7265, longitude: -73.9815),
        Restaurant(id: UUID(), name: "Golden Hour", cuisine: "Mediterranean", neighborhood: "Silver Lake",
                   city: "Los Angeles", priceLevel: 3, rating: 4.6,
                   tags: ["brunch", "date night", "cozy"], heroEmoji: "🥗",
                   latitude: 34.0877, longitude: -118.2701),
        Restaurant(id: UUID(), name: "Carnita Casa", cuisine: "Mexican", neighborhood: "Boyle Heights",
                   city: "Los Angeles", priceLevel: 1, rating: 4.8,
                   tags: ["tacos", "cheap eats", "late night"], heroEmoji: "🌮",
                   latitude: 34.0315, longitude: -118.2098)
    ]

    static var postsIndex: [UUID: Post] = [:]

    static let posts: [Post] = {
        let u = users
        let r = restaurants
        let now = Date()

        let items: [Post] = [
            Post(
                authorID: u[1].id, restaurantID: r[0].id,
                caption: "Fire noodles, literally. Bring friends and napkins. 🔥",
                media: .video(posterEmoji: "🌶️", bgHex: "#FF5733", durationSeconds: 18),
                tags: ["spicy", "late night"],
                likeCount: 842, saveCount: 128, shareCount: 33,
                createdAt: now.addingTimeInterval(-3600 * 2),
                friendsWhoLiked: [u[3].id, u[5].id]
            ),
            Post(
                authorID: u[4].id, restaurantID: r[5].id,
                caption: "Morning pastry run at Dough Hive. The kouign-amann >>>",
                media: .photo(emoji: "🥐", bgHex: "#F5C26B"),
                tags: ["pastry", "coffee"],
                likeCount: 312, saveCount: 84, shareCount: 12,
                createdAt: now.addingTimeInterval(-3600 * 6),
                friendsWhoLiked: [u[2].id]
            ),
            Post(
                authorID: u[2].id, restaurantID: r[4].id,
                caption: "Plantiful's tempeh bowl will convert anyone 🌱",
                media: .photo(emoji: "🥗", bgHex: "#8ED96C"),
                tags: ["vegan", "healthy"],
                likeCount: 156, saveCount: 42, shareCount: 4,
                createdAt: now.addingTimeInterval(-3600 * 9),
                friendsWhoLiked: []
            ),
            Post(
                authorID: u[5].id, restaurantID: r[6].id,
                caption: "Rainy day = shoyu ramen from Broth & Co. No notes.",
                media: .video(posterEmoji: "🍜", bgHex: "#5E9EEA", durationSeconds: 24),
                tags: ["ramen", "rainy day"],
                likeCount: 2044, saveCount: 398, shareCount: 77,
                createdAt: now.addingTimeInterval(-3600 * 12),
                friendsWhoLiked: [u[1].id, u[3].id, u[4].id]
            ),
            Post(
                authorID: u[3].id, restaurantID: r[2].id,
                caption: "Omakase night at Maki Maki. Worth every dollar 🍣",
                media: .photo(emoji: "🍣", bgHex: "#FF7AAD"),
                tags: ["sushi", "date night"],
                likeCount: 512, saveCount: 140, shareCount: 20,
                createdAt: now.addingTimeInterval(-3600 * 20),
                friendsWhoLiked: [u[0].id]
            ),
            Post(
                authorID: u[1].id, restaurantID: r[3].id,
                caption: "$2 tacos and zero regrets. Verde Kitchen never misses.",
                media: .photo(emoji: "🌮", bgHex: "#FFB020"),
                tags: ["tacos", "cheap eats"],
                likeCount: 980, saveCount: 201, shareCount: 44,
                createdAt: now.addingTimeInterval(-3600 * 28),
                friendsWhoLiked: [u[4].id]
            ),
            Post(
                authorID: u[0].id, restaurantID: r[1].id,
                caption: "Saturday brunch at Biscuit Baby = pure joy.",
                media: .photo(emoji: "🥞", bgHex: "#FFC85C"),
                tags: ["brunch", "cozy"],
                likeCount: 284, saveCount: 61, shareCount: 8,
                createdAt: now.addingTimeInterval(-3600 * 32),
                friendsWhoLiked: [u[2].id, u[5].id]
            )
        ]
        for p in items { postsIndex[p.id] = p }
        return items
    }()

    static func user(id: UUID) -> User? { users.first { $0.id == id } }
    static func restaurant(id: UUID) -> Restaurant? { restaurants.first { $0.id == id } }
    static func posts(byAuthor id: UUID) -> [Post] { posts.filter { $0.authorID == id } }
    static func posts(atRestaurant id: UUID) -> [Post] { posts.filter { $0.restaurantID == id } }
    static func restaurants(in city: String) -> [Restaurant] {
        restaurants.filter { $0.city.caseInsensitiveCompare(city) == .orderedSame }
    }
    static func isPost(_ post: Post, in city: String) -> Bool {
        guard let r = restaurant(id: post.restaurantID) else { return false }
        return r.city.caseInsensitiveCompare(city) == .orderedSame
    }

    static let trendingTags: [String] = [
        "brunch", "ramen", "spicy", "date night", "vegan",
        "late night", "cheap eats", "tacos", "sushi", "cozy",
        "rainy day", "coffee", "pastry", "solo", "group"
    ]

    static let notifications: [AppNotification] = {
        let u = users
        let p = posts
        let r = restaurants
        let now = Date()
        return [
            AppNotification(
                actorID: u[1].id,
                kind: .like(postID: p[0].id),
                createdAt: now.addingTimeInterval(-60 * 12),
                isRead: false
            ),
            AppNotification(
                actorID: u[5].id,
                kind: .follow,
                createdAt: now.addingTimeInterval(-60 * 40),
                isRead: false
            ),
            AppNotification(
                actorID: u[2].id,
                kind: .friendVisited(restaurantID: r[5].id),
                createdAt: now.addingTimeInterval(-3600 * 2),
                isRead: false
            ),
            AppNotification(
                actorID: u[3].id,
                kind: .mention(postID: p[4].id),
                createdAt: now.addingTimeInterval(-3600 * 5),
                isRead: true
            ),
            AppNotification(
                actorID: u[4].id,
                kind: .like(postID: p[6].id),
                createdAt: now.addingTimeInterval(-3600 * 20),
                isRead: true
            ),
            AppNotification(
                actorID: u[0].id,
                kind: .milestone(text: "You hit 1,000 followers 🎉"),
                createdAt: now.addingTimeInterval(-3600 * 30),
                isRead: true
            )
        ]
    }()
}
