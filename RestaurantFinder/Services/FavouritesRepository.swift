import Foundation

extension Notification.Name {
    /// Posted (on the main thread) whenever the set of saved favourites changes.
    static let favouritesDidChange = Notification.Name("favouritesDidChange")
}

/// Storage for the user's saved restaurants. The concrete implementation is
/// `SwiftDataFavouritesRepository`; tests inject an in-memory SwiftData store.
protocol FavouritesRepository {
    func favourites() -> [Restaurant]
    func isFavourite(_ restaurant: Restaurant) -> Bool

    /// Adds the restaurant if absent, removes it if present.
    /// - Returns: `true` if the restaurant is a favourite after the call.
    @discardableResult
    func toggle(_ restaurant: Restaurant) -> Bool

    func remove(_ restaurant: Restaurant)
}
