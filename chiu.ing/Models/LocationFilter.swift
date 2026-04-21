import Foundation

struct LocationFilter: Hashable, Codable {
    var city: String
    var radiusMiles: Double
    var usingCurrentLocation: Bool

    static let `default` = LocationFilter(
        city: "Atlanta",
        radiusMiles: 5,
        usingCurrentLocation: false
    )

    var displayText: String {
        "\(city) • \(Int(radiusMiles)) mi"
    }
}
