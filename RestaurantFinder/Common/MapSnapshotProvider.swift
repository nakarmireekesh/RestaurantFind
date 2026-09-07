import MapKit
import UIKit

/// Renders and caches static map images (`MKMapSnapshotter`) for the Favourites grid.
final class MapSnapshotProvider {

    static let shared = MapSnapshotProvider()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 120
    }

    func snapshot(for coordinate: CLLocationCoordinate2D, size: CGSize) async -> UIImage? {
        let key = "\(coordinate.latitude),\(coordinate.longitude)|\(Int(size.width))x\(Int(size.height))" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 450,
            longitudinalMeters: 450
        )
        options.size = size

        guard let snapshot = try? await MKMapSnapshotter(options: options).start() else { return nil }
        cache.setObject(snapshot.image, forKey: key)
        return snapshot.image
    }
}
