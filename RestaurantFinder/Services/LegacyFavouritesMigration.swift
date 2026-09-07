import Foundation

/// One-shot import of favourites saved by the previous JSON-file implementation.
/// After a successful import the old file is deleted so this never runs twice.
enum LegacyFavouritesMigration {

    private static var legacyFileURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("favourites.json")
    }

    static func run(into repository: FavouritesRepository) {
        guard let url = legacyFileURL,
              let data = try? Data(contentsOf: url),
              let legacy = try? JSONDecoder().decode([Restaurant].self, from: data)
        else { return }

        for restaurant in legacy where !repository.isFavourite(restaurant) {
            repository.toggle(restaurant)
        }
        try? FileManager.default.removeItem(at: url)
    }
}
