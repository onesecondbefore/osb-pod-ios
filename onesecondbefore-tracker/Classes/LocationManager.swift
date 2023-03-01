//
//  LocationManager.swift
//
//  Created by Crypton on 05/06/19.
//  Copyright © 2019 Crypton. All rights reserved.
//

import CoreLocation
import Foundation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Public functions
    public func getLocationCoordinates() -> (CLLocationDegrees, CLLocationDegrees) {
        let locManager = CLLocationManager()
        locManager.delegate = self
        locManager.distanceFilter = kCLDistanceFilterNone
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        if self.isLocationEnabled() {
             locManager.startUpdatingLocation()
        }
        let latitude = locManager.location?.coordinate.latitude ?? 0.0
        let longitude = locManager.location?.coordinate.longitude ?? 0.0
        return (latitude, longitude)
    }
    
    public func isLocationEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
}
