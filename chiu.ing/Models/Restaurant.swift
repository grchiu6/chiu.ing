import Foundation
import CoreLocation

struct Restaurant: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var cuisine: String
    var neighborhood: String
    var city: String
    var priceLevel: Int
    var rating: Double
    var tags: [String]
    var heroEmoji: String
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var priceLabel: String {
        String(repeating: "$", count: max(1, min(priceLevel, 4)))
    }
}
