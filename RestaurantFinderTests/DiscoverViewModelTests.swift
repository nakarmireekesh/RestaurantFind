import CoreLocation
import XCTest
@testable import RestaurantFinder

@MainActor
final class DiscoverViewModelTests: XCTestCase {

    private var favouritesFileURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        favouritesFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("fav-\(UUID().uuidString).json")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: favouritesFileURL)
        favouritesFileURL = nil
        try super.tearDownWithError()
    }

    func test_search_sortsResultsByDistanceFromUser() async {
        let user = CLLocation(latitude: 51.5, longitude: -0.12)
        let near = Restaurant.stub(name: "Near", latitude: 51.5008, longitude: -0.12)   // ~90 m
        let far = Restaurant.stub(name: "Far", latitude: 51.52, longitude: -0.12)       // ~2.2 km

        let sut = makeSUT(location: user, results: [far, near])

        let rows = await loadedRows(from: sut) { sut.search(query: "pasta") }

        XCTAssertEqual(rows.map(\.restaurant.name), ["Near", "Far"])
    }

    func test_search_surfacesLocationPermissionError() async {
        let sut = makeSUT(locationError: .permissionDenied, results: [])

        let message = await withState(
            from: sut,
            map: { state in
                if case .failed(let message) = state { return message }
                return nil
            },
            trigger: { sut.search(query: "") }
        )

        XCTAssertEqual(message, LocationError.permissionDenied.errorDescription)
    }

    func test_toggleFavourite_updatesRowFlag() async {
        let restaurant = Restaurant.stub(name: "Bao", latitude: 51.5, longitude: -0.12)
        let sut = makeSUT(location: CLLocation(latitude: 51.5, longitude: -0.12), results: [restaurant])

        _ = await loadedRows(from: sut) { sut.search(query: "") }
        sut.toggleFavourite(for: restaurant)

        guard case .loaded(let rows) = sut.state else {
            return XCTFail("expected loaded state")
        }
        XCTAssertEqual(rows.first?.isFavourite, true)
    }

    // MARK: - Helpers

    private func makeSUT(
        location: CLLocation = CLLocation(latitude: 0, longitude: 0),
        locationError: LocationError? = nil,
        results: [Restaurant]
    ) -> DiscoverViewModel {
        let environment = AppEnvironment(
            locationService: FakeLocationService(location: location, error: locationError),
            searchService: FakeSearchService(results: results),
            favourites: FileFavouritesRepository(fileURL: favouritesFileURL)
        )
        return DiscoverViewModel(environment: environment)
    }

    /// Runs `trigger`, then waits for the view model to reach `.loaded` and returns its rows.
    private func loadedRows(
        from sut: DiscoverViewModel,
        trigger: () -> Void
    ) async -> [DiscoverViewModel.RestaurantRow] {
        await withState(
            from: sut,
            map: { state in
                if case .loaded(let rows) = state { return rows }
                return nil
            },
            trigger: trigger
        )
    }

    /// Generic wait-for-state helper. Resolves as soon as `map` returns non-nil.
    private func withState<T>(
        from sut: DiscoverViewModel,
        map: @escaping (DiscoverViewModel.State) -> T?,
        trigger: () -> Void
    ) async -> T {
        await withCheckedContinuation { (continuation: CheckedContinuation<T, Never>) in
            var resumed = false
            sut.onStateChange = { state in
                guard !resumed, let value = map(state) else { return }
                resumed = true
                continuation.resume(returning: value)
            }
            trigger()
        }
    }
}

// MARK: - Fakes

private struct FakeLocationService: LocationProviding {
    let location: CLLocation
    let error: LocationError?

    func currentLocation() async throws -> CLLocation {
        if let error { throw error }
        return location
    }
}

private struct FakeSearchService: RestaurantSearching {
    let results: [Restaurant]

    func searchRestaurants(
        matching query: String,
        near center: CLLocationCoordinate2D
    ) async throws -> [Restaurant] {
        results
    }
}

private extension Restaurant {
    static func stub(name: String, latitude: Double, longitude: Double) -> Restaurant {
        Restaurant(
            id: "stub-\(name)",
            name: name,
            category: "Restaurant",
            latitude: latitude,
            longitude: longitude,
            street: nil,
            locality: "London",
            phoneNumber: nil,
            website: nil
        )
    }
}
