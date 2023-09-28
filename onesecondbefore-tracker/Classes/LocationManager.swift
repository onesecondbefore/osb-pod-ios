//
//  LocationManager.swift
//
//  Copyright (c) 2023 Onesecondbefore B.V. All rights reserved.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.  

import CoreLocation
import Foundation

class LocationManager: NSObject, CLLocationManagerDelegate {

    fileprivate var locationManager = CLLocationManager()
    fileprivate var locationIsEnabled = false
    fileprivate var lastKnownCoordinates: (CLLocationDegrees, CLLocationDegrees) = (0.0, 0.0)

    // MARK: - Public functions

    public func initialize() {
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if isLocationEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    public func getLocationCoordinates() -> (CLLocationDegrees, CLLocationDegrees) {
        if isLocationEnabled() {
            locationManager.startUpdatingLocation()
        }
        return lastKnownCoordinates
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locationObj = locations.last {
            lastKnownCoordinates = (locationObj.coordinate.latitude, locationObj.coordinate.longitude)
        }
    }

    public func isLocationEnabled() -> Bool {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationIsEnabled = true
        default:
            locationIsEnabled = false
        }
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
