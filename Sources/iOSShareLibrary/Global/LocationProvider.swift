//
//  LocationProvider.swift
//  iOSRepositories
//
//  Created by Order Tiger on 20/8/21.
//  Copyright © All rights reserved.
//
// swiftlint:disable all
import Combine
import CoreLocation
import Foundation
import UIKit
import iOSRepositories

public extension System {
    var location: LocationPublisher { .init() }
}

public struct LocationPublisher: Publisher {
    public typealias Output = CLLocation
    public typealias Failure = LocationProviderError
    
    public init() { }
    
    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = LocationSubscription(subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
    
    final class LocationSubscription<S: Subscriber>: NSObject, CLLocationManagerDelegate,
                                                     Subscription where S.Input == Output, S.Failure == Failure {
        var subscriber: S
        
        private var locationManager = CLLocationManager()
        private var lastLocation: CLLocation?
        private var status: LocationProviderError = .notDetermined
        
        init(subscriber: S) {
            self.subscriber = subscriber
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 50
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.showsBackgroundLocationIndicator = true
        }
        
        func request(_ demand: Subscribers.Demand) {
            self.requestAuthorization()
            if [.notDetermined, .authorizedWhenInUse, .authorizedAlways].contains(status) {
                locationManager.startUpdatingLocation()
            }
        }
        
        func cancel() {
            locationManager.stopUpdatingLocation()
        }
        
        func requestAuthorization(authorizationRequestType: CLAuthorizationStatus = .authorizedWhenInUse) {
            switch authorizationRequestType {
            case .authorizedWhenInUse:
                self.locationManager.requestWhenInUseAuthorization()
            case .authorizedAlways:
                self.locationManager.requestAlwaysAuthorization()
            default: break
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            self.status = LocationProviderError.convert(status)
            
            switch status {
            case .denied:
                requestAlert { _ in
                    self.subscriber.receive(completion: .failure(self.status))
                }
            default: break
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let newLocation = locations.last else { return }
            if let last = lastLocation, last.coordinate == newLocation.coordinate { return }
        
            self.lastLocation = newLocation
            _ = subscriber.receive(newLocation)
        }
        
        private func requestAlert(cancel: @escaping ((UIAlertAction) -> Void)) {
            let alertController = UIAlertController(title: "Enable Location Access",
                                                    message: "The location access for this app is set to 'never'. Enable location access in the application settings. Go to Settings now?",
                                                    preferredStyle: .alert)
            
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                guard let BUNDLE_IDENTIFIER = Bundle.main.bundleIdentifier else { return }
                guard let settingsUrl = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION/\(BUNDLE_IDENTIFIER)") else { return }
                UIApplication.shared.open(settingsUrl)
            }
            alertController.addAction(settingsAction)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: cancel)
            alertController.addAction(cancelAction)
            
            UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
        
        //            func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //                guard let clError = error as? CLError else { return }
        //                switch clError {
        //                case CLError.denied:
        //                    requestAlert()
        //                    self.requestAuthorization()
        //                default:
        //                    break
        //                }
        //            }
    }
}

@MainActor
public class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Error>?
    let manager = CLLocationManager()
    private var status: LocationProviderError = .notDetermined

    public override init() {
        super.init()
        manager.delegate = self
    }

    public func requestLocation() async throws -> CLLocationCoordinate2D? {
        try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            self.requestAuthorization()
            if [.notDetermined, .authorizedWhenInUse, .authorizedAlways].contains(status) {
                manager.requestLocation()
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.first?.coordinate else { return }
        locationContinuation?.resume(returning: coord)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.status = LocationProviderError.convert(status)
        
        switch status {
        case .denied:
            requestAlert { [weak self] _ in
                guard let self = self else { return }
                self.locationContinuation?.resume(throwing: self.status)
            }
        default: manager.requestLocation()
        }
    }
    
    func requestAuthorization(authorizationRequestType: CLAuthorizationStatus = .authorizedWhenInUse) {
        switch authorizationRequestType {
        case .authorizedWhenInUse:
            self.manager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            self.manager.requestAlwaysAuthorization()
        default: break
        }
    }
    
    private func requestAlert(cancel: @escaping ((UIAlertAction) -> Void)) {
        let alertController = UIAlertController(title: "Enable Location Access",
                                                message: "The location access for this app is set to 'never'. Enable location access in the application settings. Go to Settings now?",
                                                preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let BUNDLE_IDENTIFIER = Bundle.main.bundleIdentifier else { return }
            guard let settingsUrl = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION/\(BUNDLE_IDENTIFIER)") else { return }
            UIApplication.shared.open(settingsUrl)
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: cancel)
        alertController.addAction(cancelAction)
        
        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

public enum LocationProviderError: Error {
    case notDetermined, restricted, denied, authorizedAlways, authorizedWhenInUse, noAuthorization
    
    static func convert(_ status: CLAuthorizationStatus) -> Self {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorizedAlways: return .authorizedAlways
        case .authorizedWhenInUse: return .authorizedWhenInUse
        @unknown default: return .noAuthorization
        }
    }
}
