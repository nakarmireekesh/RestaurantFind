import CoreLocation

/// Resolves the device's current location, requesting permission the first time.
protocol LocationProviding {
    func currentLocation() async throws -> CLLocation
}

enum LocationError: LocalizedError {
    case permissionDenied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location access is off. Turn it on in Settings to find restaurants near you."
        case .unavailable:
            return "Couldn't determine your location. Please try again."
        }
    }
}

/// `CLLocationManager`-backed implementation that bridges the delegate callbacks
/// into a single `async` call.
final class LocationService: NSObject, LocationProviding, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            // Only one request is in flight at a time; fail any earlier one.
            self.continuation?.resume(throwing: LocationError.unavailable)
            self.continuation = continuation

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                finish(with: .failure(LocationError.permissionDenied))
            @unknown default:
                finish(with: .failure(LocationError.unavailable))
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Ignore the callback CLLocationManager fires just from setting its delegate.
        guard continuation != nil else { return }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            finish(with: .failure(LocationError.permissionDenied))
        case .notDetermined:
            break // Still waiting for the user to answer the prompt.
        @unknown default:
            finish(with: .failure(LocationError.unavailable))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finish(with: .failure(LocationError.unavailable))
            return
        }
        finish(with: .success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(with: .failure(LocationError.unavailable))
    }

    private func finish(with result: Result<CLLocation, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}
