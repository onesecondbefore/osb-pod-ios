//
//  LocationManager.swift
//
//  Created by Crypton on 05/06/19.
//  Copyright (c) 2023 Onesecondbefore B.V. All rights reserved.
//

import CoreLocation
import Foundation

class LocationManager: NSObject, CLLocationManagerDelegate {

    fileprivate var locationManager = CLLocationManager()
    fileprivate var locationIsEnabled = false

    // MARK: - Public functions

    public func initialize() {
        locationManager.delegate = self
    }

    public func getLocationCoordinates() -> (CLLocationDegrees, CLLocationDegrees) {
        let locManager = CLLocationManager()
        locManager.delegate = self
        locManager.distanceFilter = kCLDistanceFilterNone
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        if isLocationEnabled() {
            locManager.startUpdatingLocation()
        }
        let latitude = locManager.location?.coordinate.latitude ?? 0.0
        let longitude = locManager.location?.coordinate.longitude ?? 0.0
        return (latitude, longitude)
    }

    public func isLocationEnabled() -> Bool {
        return locationIsEnabled
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse || status == CLAuthorizationStatus.authorizedAlways {
            locationIsEnabled = true
        } else {
            locationIsEnabled = false
        }
    }
}
