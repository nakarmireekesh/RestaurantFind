import Foundation

/// The app's composition root.
///
/// Every screen is handed one of these instead of reaching for singletons, so the
/// same view models can be driven by fakes in unit tests or Xcode previews.
struct AppEnvironment {
    let locationService: LocationProviding
    let searchService: RestaurantSearching
    let favourites: FavouritesRepository

    /// The configuration used by the running app.
    static let live = AppEnvironment(
        locationService: LocationService(),
        searchService: MapKitRestaurantSearchService(),
        favourites: FileFavouritesRepository()
    )
}
