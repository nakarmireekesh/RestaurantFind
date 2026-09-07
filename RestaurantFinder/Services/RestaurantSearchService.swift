import MapKit

/// Searches for restaurants near a coordinate.
protocol RestaurantSearching {
    func searchRestaurants(
        matching query: String,
        near center: CLLocationCoordinate2D
    ) async throws -> [Restaurant]
}

/// Uses Apple's `MKLocalSearch` — no API key, no billing account, results
/// scoped to points of interest in a ~4 km box around the user.
final class MapKitRestaurantSearchService: RestaurantSearching {

    private let searchRadiusMeters: CLLocationDistance = 4_000

    func searchRestaurants(
        matching query: String,
        near center: CLLocationCoordinate2D
    ) async throws -> [Restaurant] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query.nilIfEmpty ?? "restaurant"
        request.region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: searchRadiusMeters,
            longitudinalMeters: searchRadiusMeters
        )
        request.resultTypes = [.pointOfInterest]

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.compactMap(Restaurant.init(mapItem:))
    }
}
