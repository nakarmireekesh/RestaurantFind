import SwiftData
import XCTest
@testable import RestaurantFinder

final class SwiftDataFavouritesRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var sut: SwiftDataFavouritesRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try ModelContainer(
            for: FavouriteRestaurant.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        sut = SwiftDataFavouritesRepository(container: container)
    }

    override func tearDownWithError() throws {
        sut = nil
        container = nil
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

    func test_favourites_persistInTheStoreAcrossContexts() {
        sut.toggle(.stub(name: "Brat"))

        let another = SwiftDataFavouritesRepository(container: container)

        XCTAssertEqual(another.favourites().map(\.name), ["Brat"])
    }

    func test_remove_isNoOpForUnknownRestaurant() {
        sut.toggle(.stub(name: "Kiln"))

        sut.remove(.stub(name: "Never Saved"))

        XCTAssertEqual(sut.favourites().count, 1)
    }

    func test_favourites_areReturnedMostRecentFirst() {
        sut.toggle(.stub(name: "First"))
        sut.toggle(.stub(name: "Second"))

        XCTAssertEqual(sut.favourites().map(\.name), ["Second", "First"])
    }

    func test_toggle_twiceForSameRestaurantDoesNotDuplicate() {
        let restaurant = Restaurant.stub(name: "Brat")
        sut.toggle(restaurant)
        sut.toggle(restaurant) // remove
        sut.toggle(restaurant) // add again

        XCTAssertEqual(sut.favourites().count, 1)
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
