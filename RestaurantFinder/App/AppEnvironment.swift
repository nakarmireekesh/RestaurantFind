import Foundation
import SwiftData

/// The app's composition root.
///
/// Every screen is handed one of these instead of reaching for singletons, so the
/// same view models can be driven by fakes / in-memory stores in unit tests.
struct AppEnvironment {
    let locationService: LocationProviding
    let searchService: RestaurantSearching
    let favourites: FavouritesRepository

    /// The configuration used by the running app.
    static let live: AppEnvironment = {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: FavouriteRestaurant.self)
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }

        let favourites = SwiftDataFavouritesRepository(container: container)
        LegacyFavouritesMigration.run(into: favourites)

        return AppEnvironment(
            locationService: LocationService(),
            searchService: MapKitRestaurantSearchService(),
            favourites: favourites
        )
    }()
}
