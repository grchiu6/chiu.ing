import Foundation

struct AppNotification: Identifiable, Hashable {
    enum Kind: Hashable {
        case like(postID: UUID)
        case follow
        case mention(postID: UUID)
        case friendVisited(restaurantID: UUID)
        case milestone(text: String)
    }

    let id: UUID
    var actorID: UUID
    var kind: Kind
    var createdAt: Date
    var isRead: Bool

    init(
        id: UUID = UUID(),
        actorID: UUID,
        kind: Kind,
        createdAt: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.actorID = actorID
        self.kind = kind
        self.createdAt = createdAt
        self.isRead = isRead
    }
}
