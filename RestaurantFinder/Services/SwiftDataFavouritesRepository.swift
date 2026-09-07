import Foundation
import SwiftData

/// `FavouritesRepository` backed by SwiftData. Saved restaurants live in a local
/// SQLite store, so they survive relaunching the app.
///
/// The repository owns its own `ModelContext` and is expected to be used from the
/// main thread (all its callers are `@MainActor` view models).
final class SwiftDataFavouritesRepository: FavouritesRepository {

    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    func favourites() -> [Restaurant] {
        let descriptor = FetchDescriptor<FavouriteRestaurant>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        let models = (try? context.fetch(descriptor)) ?? []
        return models.map(\.restaurant)
    }

    func isFavourite(_ restaurant: Restaurant) -> Bool {
        model(withID: restaurant.id) != nil
    }

    @discardableResult
    func toggle(_ restaurant: Restaurant) -> Bool {
        if let existing = model(withID: restaurant.id) {
            context.delete(existing)
            persist()
            return false
        } else {
            context.insert(FavouriteRestaurant(from: restaurant))
            persist()
            return true
        }
    }

    func remove(_ restaurant: Restaurant) {
        guard let existing = model(withID: restaurant.id) else { return }
        context.delete(existing)
        persist()
    }

    // MARK: - Helpers

    private func model(withID id: String) -> FavouriteRestaurant? {
        var descriptor = FetchDescriptor<FavouriteRestaurant>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func persist() {
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save favourites: \(error)")
        }
        postChange()
    }

    private func postChange() {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: .favouritesDidChange, object: nil)
        } else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .favouritesDidChange, object: nil)
            }
        }
    }
}
