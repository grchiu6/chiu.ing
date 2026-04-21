import Foundation
import Combine
import SwiftUI

final class SessionStore: ObservableObject {
    @Published var currentUser: User
    @Published var locationFilter: LocationFilter
    @Published var likedPostIDs: Set<UUID> = []
    @Published var savedPostIDs: Set<UUID> = []
    @Published var followedUserIDs: Set<UUID> = []
    @Published var visitedRestaurantIDs: Set<UUID> = []
    @Published var tasteTags: Set<String> = []
    @AppStorage("chiuing.hasOnboarded") var hasOnboarded: Bool = false

    init(
        currentUser: User = MockData.currentUser,
        locationFilter: LocationFilter = .default
    ) {
        self.currentUser = currentUser
        self.locationFilter = locationFilter
        self.followedUserIDs = Set(MockData.users.prefix(4).map(\.id))
    }

    func toggleLike(_ post: Post) {
        Haptics.tap()
        if likedPostIDs.contains(post.id) {
            likedPostIDs.remove(post.id)
        } else {
            likedPostIDs.insert(post.id)
        }
    }

    func toggleSave(_ post: Post) {
        Haptics.soft()
        if savedPostIDs.contains(post.id) {
            savedPostIDs.remove(post.id)
        } else {
            savedPostIDs.insert(post.id)
        }
    }

    func toggleFollow(_ user: User) {
        Haptics.tap()
        if followedUserIDs.contains(user.id) {
            followedUserIDs.remove(user.id)
        } else {
            followedUserIDs.insert(user.id)
        }
    }

    func toggleVisit(_ restaurant: Restaurant) {
        Haptics.success()
        if visitedRestaurantIDs.contains(restaurant.id) {
            visitedRestaurantIDs.remove(restaurant.id)
        } else {
            visitedRestaurantIDs.insert(restaurant.id)
        }
    }
}
