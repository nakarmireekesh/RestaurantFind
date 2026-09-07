import CoreLocation
import Foundation

/// Drives the Discover tab: resolves the user's location once, runs MapKit
/// searches, sorts results by distance and tracks which are favourited.
@MainActor
final class DiscoverViewModel {

    enum State {
        case idle
        case loading
        case loaded([RestaurantRow])
        case empty(String)
        case failed(String)
    }

    struct RestaurantRow {
        let restaurant: Restaurant
        let distanceText: String
        var isFavourite: Bool
    }

    let favouritesRepository: FavouritesRepository

    private let locationService: LocationProviding
    private let searchService: RestaurantSearching
    private let distanceFormatter = DistanceFormatter()

    private var cachedCenter: CLLocationCoordinate2D?
    private var currentQuery = ""
    private var searchTask: Task<Void, Never>?

    var onStateChange: ((State) -> Void)?
    private(set) var state: State = .idle {
        didSet { onStateChange?(state) }
    }

    init(environment: AppEnvironment) {
        self.locationService = environment.locationService
        self.searchService = environment.searchService
        self.favouritesRepository = environment.favourites
    }

    // MARK: - Intent

    func onAppear() {
        switch state {
        case .idle:
            search(query: "")
        case .loaded:
            refreshFavouriteFlags()
        default:
            break
        }
    }

    func search(query: String) {
        currentQuery = query
        searchTask?.cancel()
        state = .loading

        searchTask = Task {
            do {
                let center = try await resolveCenter()
                let restaurants = try await searchService.searchRestaurants(matching: query, near: center)
                try Task.checkCancellation()

                let origin = CLLocation(latitude: center.latitude, longitude: center.longitude)
                let rows = restaurants
                    .sorted { $0.location.distance(from: origin) < $1.location.distance(from: origin) }
                    .map { restaurant in
                        RestaurantRow(
                            restaurant: restaurant,
                            distanceText: distanceFormatter.string(
                                fromMeters: restaurant.location.distance(from: origin)
                            ),
                            isFavourite: favouritesRepository.isFavourite(restaurant)
                        )
                    }

                if rows.isEmpty {
                    let scope = query.nilIfEmpty.map { "for “\($0)”" } ?? "nearby"
                    state = .empty("No restaurants found \(scope).")
                } else {
                    state = .loaded(rows)
                }
            } catch is CancellationError {
                // A newer search superseded this one; leave its state alone.
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                state = .failed(message)
            }
        }
    }

    func retry() {
        search(query: currentQuery)
    }

    func toggleFavourite(for restaurant: Restaurant) {
        favouritesRepository.toggle(restaurant)
        refreshFavouriteFlags()
    }

    // MARK: - Helpers

    private func resolveCenter() async throws -> CLLocationCoordinate2D {
        if let cachedCenter { return cachedCenter }
        let coordinate = try await locationService.currentLocation().coordinate
        cachedCenter = coordinate
        return coordinate
    }

    private func refreshFavouriteFlags() {
        guard case .loaded(var rows) = state else { return }
        for index in rows.indices {
            rows[index].isFavourite = favouritesRepository.isFavourite(rows[index].restaurant)
        }
        state = .loaded(rows)
    }
}
