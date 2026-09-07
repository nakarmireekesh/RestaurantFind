import Foundation

extension Notification.Name {
    /// Posted (on the main thread) whenever the set of saved favourites changes.
    static let favouritesDidChange = Notification.Name("favouritesDidChange")
}

protocol FavouritesRepository {
    func favourites() -> [Restaurant]
    func isFavourite(_ restaurant: Restaurant) -> Bool
    /// Adds the restaurant if absent, removes it if present.
    /// - Returns: `true` if the restaurant is a favourite after the call.
    @discardableResult
    func toggle(_ restaurant: Restaurant) -> Bool
    func remove(_ restaurant: Restaurant)
}

/// Stores favourites as a JSON file in Application Support.
///
/// The file URL is injectable so tests can point it at a scratch file. A small
/// in-memory cache keeps reads cheap; a serial queue guards mutations.
final class FileFavouritesRepository: FavouritesRepository {

    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.reekesh.RestaurantFinder.favourites")
    private var cache: [Restaurant]

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let directory = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            self.fileURL = directory.appendingPathComponent("favourites.json")
        }
        self.cache = Self.load(from: self.fileURL)
    }

    func favourites() -> [Restaurant] {
        queue.sync { cache }
    }

    func isFavourite(_ restaurant: Restaurant) -> Bool {
        queue.sync { cache.contains { $0.id == restaurant.id } }
    }

    @discardableResult
    func toggle(_ restaurant: Restaurant) -> Bool {
        let isFavouriteNow: Bool = queue.sync {
            if let index = cache.firstIndex(where: { $0.id == restaurant.id }) {
                cache.remove(at: index)
                return false
            }
            cache.insert(restaurant, at: 0)
            return true
        }
        persist()
        postChange()
        return isFavouriteNow
    }

    func remove(_ restaurant: Restaurant) {
        queue.sync { cache.removeAll { $0.id == restaurant.id } }
        persist()
        postChange()
    }

    // MARK: - Persistence

    private func persist() {
        let snapshot = queue.sync { cache }
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Failed to save favourites: \(error)")
        }
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

    private static func load(from url: URL) -> [Restaurant] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Restaurant].self, from: data)) ?? []
    }
}
