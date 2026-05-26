// CurrentCountryProvider.swift
// Xplora

import CoreLocation
import Foundation

enum CurrentLocationError: Error {
    case permissionDenied
    case locationUnavailable
    case geocodingFailed
    case countryNotFound
}

protocol CurrentCountryProviding: AnyObject {
    func requestCurrentCountryCode(completion: @escaping (Result<String, CurrentLocationError>) -> Void)
}

final class CurrentCountryProvider: NSObject, CurrentCountryProviding {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var pendingCompletion: ((Result<String, CurrentLocationError>) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCurrentCountryCode(completion: @escaping (Result<String, CurrentLocationError>) -> Void) {
        pendingCompletion = completion
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            finish(.failure(.permissionDenied))
        @unknown default:
            finish(.failure(.permissionDenied))
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard error == nil, let code = placemarks?.first?.isoCountryCode, !code.isEmpty else {
                self?.finish(.failure(.geocodingFailed))
                return
            }
            self?.finish(.success(code))
        }
    }

    private func finish(_ result: Result<String, CurrentLocationError>) {
        guard let completion = pendingCompletion else { return }
        pendingCompletion = nil
        DispatchQueue.main.async { completion(result) }
    }
}

extension CurrentCountryProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            finish(.failure(.permissionDenied))
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            finish(.failure(.locationUnavailable))
            return
        }
        reverseGeocode(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(.failure(.locationUnavailable))
    }
}
