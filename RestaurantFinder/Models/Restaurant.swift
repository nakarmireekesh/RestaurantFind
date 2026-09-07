import CoreLocation
import MapKit

/// A restaurant returned by search or stored as a favourite.
///
/// It is deliberately built from primitive values (not `MKMapItem` /
/// `CLLocationCoordinate2D`) so it is trivially `Codable` for persistence and
/// `Hashable` for use with diffable data sources.
struct Restaurant: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let category: String?
    let latitude: Double
    let longitude: Double
    let street: String?
    let locality: String?
    let phoneNumber: String?
    let website: URL?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /// e.g. "12 Acklam Road, London" — empty when MapKit gave us no address.
    var shortAddress: String {
        [street, locality].compactMap { $0?.nilIfEmpty }.joined(separator: ", ")
    }
}

extension Restaurant {
    /// Builds a `Restaurant` from a MapKit point-of-interest search result.
    /// Returns `nil` for results without a name (they can't be shown or saved usefully).
    init?(mapItem: MKMapItem) {
        guard let name = mapItem.name else { return nil }
        let placemark = mapItem.placemark
        let coordinate = placemark.coordinate

        self.id = "\(name)|\(coordinate.latitude),\(coordinate.longitude)"
        self.name = name
        self.category = mapItem.pointOfInterestCategory?.friendlyName
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.street = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")
            .nilIfEmpty
        self.locality = placemark.locality
        self.phoneNumber = mapItem.phoneNumber
        self.website = mapItem.url
    }
}
