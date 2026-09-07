# RestaurantFinder

A small UIKit app for discovering restaurants near you and saving the ones you
like. Built as a portfolio project: programmatic UIKit, MVVM, protocol-based
services, unit tests, no third-party dependencies.

| Discover | Detail | Favourites |
| --- | --- | --- |
| Search + distance-sorted list | Map, address, call, website | Saved list, swipe to delete |

> Add screenshots to `Docs/` and update this table once you can run it.

## What it does

- **Discover tab** — asks for location permission, then lists restaurants within
  ~4 km, closest first. A search bar filters by free text ("sushi", "coffee",
  "burger"). Pull to refresh.
- **Detail screen** — an embedded map with a pin, the category, and tappable
  rows: address opens Apple Maps, phone starts a call, website opens Safari.
- **Favourites tab** — tap the heart anywhere to save a restaurant. Favourites
  are stored on device as JSON and survive relaunch. Swipe a row to delete.

## Tech

| Area | Choice |
| --- | --- |
| UI | UIKit, programmatic Auto Layout, no storyboards (except the generated launch screen) |
| Architecture | MVVM — view controllers are thin, view models are `@MainActor` and hold all logic |
| Search | Apple **MapKit** `MKLocalSearch` — no API key, no billing account |
| Location | `CLLocationManager` wrapped in an `async` call |
| Persistence | `Codable` favourites written to a JSON file in Application Support, behind a `FavouritesRepository` protocol |
| Concurrency | `async`/`await`, cancellable search `Task` |
| Tests | XCTest — repository round-trip + view model behaviour with fakes |
| Dependencies | none |

## Project layout

```
RestaurantFinder/
├── App/            App/Scene delegates, composition root (AppEnvironment), root tab bar
├── Models/         Restaurant value type (+ MKMapItem mapping)
├── Services/       LocationService, RestaurantSearchService, FavouritesRepository (protocols + impls)
├── Features/
│   ├── Discover/   list + search + view model
│   ├── Detail/     detail screen + view model
│   └── Favourites/ saved list + view model
├── Common/         formatters and small extensions
└── Resources/      asset catalog, Info.plist
RestaurantFinderTests/   unit tests
```

Every screen receives an `AppEnvironment` (the composition root) instead of
reaching for singletons, so view models can be driven by fakes in tests — see
`RestaurantFinderTests/DiscoverViewModelTests.swift`.

## Running it

1. Install **Xcode** from the Mac App Store (this project targets iOS 17+, so
   Xcode 16 or newer). First launch will install the command line tools.
2. Open `RestaurantFinder.xcodeproj`.
3. Select an iPhone simulator and press **⌘R**.
4. To search real results in the simulator, set a location:
   **Features ▸ Location ▸ Custom Location…**. On a device it uses GPS.
5. Run tests with **⌘U**.

> **Testing note:** `MKLocalSearch` uses the Maps data backend for your Mac's
> **Region** (System Settings ▸ General ▸ Language & Region). If your region is
> set to mainland China, Apple routes through AutoNavi, and searches only return
> results for coordinates inside China — pick a simulator location to match your
> region (e.g. a China city, or switch your Mac's region), or you'll see
> "MKErrorDomain error 4" / no results.

From the terminal (after Xcode is installed):

```bash
xcodebuild -project RestaurantFinder.xcodeproj -scheme RestaurantFinder -destination 'platform=iOS Simulator,name=iPhone 16' build test
```

## Roadmap / nice next steps

These are deliberately left open — each is a small, self-contained addition that
makes a good follow-up commit:

- [ ] Category filter chips (derive from `pointOfInterestCategory`)
- [ ] `UICollectionView` compositional layout instead of `UITableView`
- [ ] Map view of results with clustering
- [ ] "Open now" indicator (needs a details API — Google Places or Foursquare)
- [ ] Snapshot the map on the detail screen instead of a live `MKMapView`
- [ ] Swap the JSON store for Core Data or a Supabase-backed sync layer
      (the `FavouritesRepository` protocol is the only thing that changes)
- [ ] Diffable data source + `NSFetchedResultsController`-style updates
- [ ] UI tests for the search → detail → favourite flow

## Troubleshooting: project won't open

The `.xcodeproj` here is hand-written. If Xcode refuses to open it or the file
list looks wrong, recreate it in ~3 minutes — the source is all standard:

1. **File ▸ New ▸ Project ▸ App**. Product name `RestaurantFinder`, interface
   **Storyboard** → then delete `Main.storyboard` and the storyboard entry in
   Info; or pick a bare template. Language Swift, no Core Data, include tests.
2. Delete the generated `ViewController.swift` / `Main.storyboard`.
3. Drag the `RestaurantFinder/App`, `Models`, `Services`, `Features`, `Common`,
   `Resources` folders into the app target ("Create groups").
4. Drag the files in `RestaurantFinderTests/` into the test target.
5. In the app target's Info tab, confirm the scene manifest points its delegate
   class at `$(PRODUCT_MODULE_NAME).SceneDelegate` and add
   `NSLocationWhenInUseUsageDescription` (see `RestaurantFinder/Info.plist`).
6. Set the app target's deployment target to iOS 17.
