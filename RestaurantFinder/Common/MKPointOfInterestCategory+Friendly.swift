import MapKit

extension MKPointOfInterestCategory {
    /// A short, human-readable label for the categories a food search tends to return.
    var friendlyName: String {
        switch self {
        case .restaurant: return "Restaurant"
        case .cafe: return "Café"
        case .bakery: return "Bakery"
        case .brewery: return "Brewery"
        case .winery: return "Winery"
        case .nightlife: return "Bar"
        case .foodMarket: return "Food Market"
        default:
            // Fall back to the raw identifier without Apple's prefix,
            // e.g. "MKPOICategoryIceCream" -> "IceCream".
            return rawValue.replacingOccurrences(of: "MKPOICategory", with: "")
        }
    }
}
