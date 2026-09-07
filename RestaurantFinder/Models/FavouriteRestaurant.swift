import Foundation
import SwiftData

/// SwiftData record for a saved restaurant. Kept separate from the plain
/// `Restaurant` value type so the domain model stays free of persistence concerns.
@Model
final class FavouriteRestaurant {

    @Attribute(.unique) var id: String
    var name: String
    var category: String?
    var latitude: Double
    var longitude: Double
    var street: String?
    var locality: String?
    var phoneNumber: String?
    var website: URL?
    var savedAt: Date

    init(from restaurant: Restaurant, savedAt: Date = .now) {
        self.id = restaurant.id
        self.name = restaurant.name
        self.category = restaurant.category
        self.latitude = restaurant.latitude
        self.longitude = restaurant.longitude
        self.street = restaurant.street
        self.locality = restaurant.locality
        self.phoneNumber = restaurant.phoneNumber
        self.website = restaurant.website
        self.savedAt = savedAt
    }

    var restaurant: Restaurant {
        Restaurant(
            id: id,
            name: name,
            category: category,
            latitude: latitude,
            longitude: longitude,
            street: street,
            locality: locality,
            phoneNumber: phoneNumber,
            website: website
        )
    }
}
