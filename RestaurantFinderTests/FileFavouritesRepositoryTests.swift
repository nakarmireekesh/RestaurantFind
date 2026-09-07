import XCTest
@testable import RestaurantFinder

final class FileFavouritesRepositoryTests: XCTestCase {

    private var fileURL: URL!
    private var sut: FileFavouritesRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("favourites-\(UUID().uuidString).json")
        sut = FileFavouritesRepository(fileURL: fileURL)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: fileURL)
        sut = nil
        fileURL = nil
        try super.tearDownWithError()
    }

    func test_toggle_addsThenRemovesRestaurant() {
        let restaurant = Restaurant.stub(name: "Padella")
        XCTAssertFalse(sut.isFavourite(restaurant))

        XCTAssertTrue(sut.toggle(restaurant), "toggle should report the restaurant as now-favourited")
        XCTAssertTrue(sut.isFavourite(restaurant))
        XCTAssertEqual(sut.favourites().count, 1)

        XCTAssertFalse(sut.toggle(restaurant), "second toggle should report it as no longer favourited")
        XCTAssertTrue(sut.favourites().isEmpty)
    }

    func test_favourites_persistAcrossInstances() {
        sut.toggle(.stub(name: "Brat"))

        let reloaded = FileFavouritesRepository(fileURL: fileURL)

        XCTAssertEqual(reloaded.favourites().map(\.name), ["Brat"])
    }

    func test_remove_isNoOpForUnknownRestaurant() {
        sut.toggle(.stub(name: "Kiln"))

        sut.remove(.stub(name: "Never Saved"))

        XCTAssertEqual(sut.favourites().count, 1)
    }

    func test_mostRecentlyToggledRestaurantComesFirst() {
        sut.toggle(.stub(name: "First"))
        sut.toggle(.stub(name: "Second"))

        XCTAssertEqual(sut.favourites().map(\.name), ["Second", "First"])
    }
}

private extension Restaurant {
    static func stub(name: String) -> Restaurant {
        Restaurant(
            id: "stub-\(name)",
            name: name,
            category: "Restaurant",
            latitude: 51.5074,
            longitude: -0.1278,
            street: "1 Test Street",
            locality: "London",
            phoneNumber: "+44 20 7946 0000",
            website: URL(string: "https://example.com")
        )
    }
}
