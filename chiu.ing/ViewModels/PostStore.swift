import Foundation
import Combine

final class PostStore: ObservableObject {
    @Published private(set) var userCreatedPosts: [Post] = []

    var allPosts: [Post] {
        (userCreatedPosts + MockData.posts).sorted { $0.createdAt > $1.createdAt }
    }

    func add(_ post: Post) {
        userCreatedPosts.insert(post, at: 0)
    }

    func posts(byAuthor id: UUID) -> [Post] {
        allPosts.filter { $0.authorID == id }
    }

    func posts(atRestaurant id: UUID) -> [Post] {
        allPosts.filter { $0.restaurantID == id }
    }
}
