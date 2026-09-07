import Foundation
import MapKit

/// Thin wrapper around `MKDistanceFormatter` with the app's defaults applied
/// (abbreviated, locale-aware units — "450 m", "1.2 mi", …).
struct DistanceFormatter {
    private let formatter: MKDistanceFormatter

    init() {
        formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
    }

    func string(fromMeters meters: CLLocationDistance) -> String {
        formatter.string(fromDistance: meters)
    }
}
