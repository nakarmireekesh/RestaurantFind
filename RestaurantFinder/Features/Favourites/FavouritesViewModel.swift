import Foundation

/// Backs the Favourites tab. Mirrors the repository and refreshes itself
/// whenever favourites change anywhere in the app.
@MainActor
final class FavouritesViewModel {

    let favouritesRepository: FavouritesRepository

    private(set) var restaurants: [Restaurant] = []
    var onChange: (() -> Void)?

    var isEmpty: Bool { restaurants.isEmpty }

    init(environment: AppEnvironment) {
        self.favouritesRepository = environment.favourites
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reload),
            name: .favouritesDidChange,
            object: nil
        )
    }

    /// `.favouritesDidChange` is always posted on the main thread, so this
    /// `@MainActor` method is safe as a notification selector.
    @objc func reload() {
        restaurants = favouritesRepository.favourites()
        onChange?()
    }

    func removeRestaurant(at index: Int) {
        guard restaurants.indices.contains(index) else { return }
        favouritesRepository.remove(restaurants[index])
        reload()
    }
}
