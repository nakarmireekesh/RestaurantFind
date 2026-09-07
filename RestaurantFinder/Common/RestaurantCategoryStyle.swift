import Foundation

/// Maps a friendly category name (from `MKPointOfInterestCategory.friendlyName`)
/// to an SF Symbol, used for the round icon badge in the Discover list.
enum RestaurantCategoryStyle {
    static func symbolName(for category: String?) -> String {
        switch category {
        case "Café":        return "cup.and.saucer.fill"
        case "Bar":         return "wineglass.fill"
        case "Bakery":      return "birthday.cake.fill"
        case "Brewery":     return "mug.fill"
        case "Winery":      return "wineglass"
        case "Food Market": return "basket.fill"
        default:            return "fork.knife"
        }
    }
}
