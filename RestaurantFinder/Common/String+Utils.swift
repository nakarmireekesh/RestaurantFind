import Foundation

extension String {
    /// The trimmed string, or `nil` when it is empty after trimming whitespace.
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
