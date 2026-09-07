import CoreLocation
import Foundation

/// Drives the Discover tab: resolves the user's location once, runs MapKit
/// searches, sorts results by distance, builds the category filter chips and
/// tracks which results are favourited.
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

    struct CategoryChip: Hashable {
        let title: String
        let isAll: Bool
    }

    let favouritesRepository: FavouritesRepository

    private let locationService: LocationProviding
    private let searchService: RestaurantSearching
    private let distanceFormatter = DistanceFormatter()
    private let allChipTitle = "All"

    private var cachedCenter: CLLocationCoordinate2D?
    private var currentQuery = ""
    private var searchTask: Task<Void, Never>?
    private var allRows: [RestaurantRow] = []

    private(set) var chips: [CategoryChip] = []
    private(set) var selectedChipTitle: String

    var onStateChange: ((State) -> Void)?
    var onChipsChange: (() -> Void)?

    private(set) var state: State = .idle {
        didSet { onStateChange?(state) }
    }

    init(environment: AppEnvironment) {
        self.locationService = environment.locationService
        self.searchService = environment.searchService
        self.favouritesRepository = environment.favourites
        self.selectedChipTitle = allChipTitle
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
                allRows = restaurants
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

                rebuildChips()

                if allRows.isEmpty {
                    let scope = query.nilIfEmpty.map { "for “\($0)”" } ?? "nearby"
                    state = .empty("No restaurants found \(scope).")
                } else {
                    emitLoaded()
                }
            } catch is CancellationError {
                // A newer search superseded this one; leave its state alone.
            } catch {
                allRows = []
                rebuildChips()
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                state = .failed(message)
            }
        }
    }

    func retry() {
        search(query: currentQuery)
    }

    func selectChip(title: String) {
        guard title != selectedChipTitle, !allRows.isEmpty else { return }
        selectedChipTitle = title
        onChipsChange?()
        emitLoaded()
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

    /// Rebuilds the chip list from the categories present in the current results,
    /// resetting the selection to "All" if the selected category is gone.
    private func rebuildChips() {
        let present = Set(allRows.compactMap { $0.restaurant.category })
        var newChips = [CategoryChip(title: allChipTitle, isAll: true)]
        newChips += present.sorted().map { CategoryChip(title: $0, isAll: false) }
        chips = newChips
        if !newChips.contains(where: { $0.title == selectedChipTitle }) {
            selectedChipTitle = allChipTitle
        }
        onChipsChange?()
    }

    private func emitLoaded() {
        if selectedChipTitle == allChipTitle {
            state = .loaded(allRows)
        } else {
            state = .loaded(allRows.filter { $0.restaurant.category == selectedChipTitle })
        }
    }

    private func refreshFavouriteFlags() {
        guard !allRows.isEmpty else { return }
        for index in allRows.indices {
            allRows[index].isFavourite = favouritesRepository.isFavourite(allRows[index].restaurant)
        }
        if case .loaded = state {
            emitLoaded()
        }
    }
}
