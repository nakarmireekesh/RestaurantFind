import Foundation

/// Backs the detail screen: exposes the restaurant plus favourite state,
/// and owns the toggle logic.
@MainActor
final class RestaurantDetailViewModel {

    let restaurant: Restaurant
    private let favourites: FavouritesRepository

    /// Called after a toggle with the new favourite state.
    var onFavouriteChange: ((Bool) -> Void)?

    init(restaurant: Restaurant, favourites: FavouritesRepository) {
        self.restaurant = restaurant
        self.favourites = favourites
    }

    var isFavourite: Bool {
        favourites.isFavourite(restaurant)
    }

    func toggleFavourite() {
        favourites.toggle(restaurant)
        onFavouriteChange?(isFavourite)
    }
}
