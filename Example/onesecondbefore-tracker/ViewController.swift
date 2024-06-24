//
//  ViewController.swift
//  onesecondbefore-tracker
//
//  Copyright (c) 2023 Onesecondbefore B.V. All rights reserved.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.

import CoreLocation
import onesecondbefore_tracker
import UIKit

// Needed for requesting Tracking permission
import AdSupport
import AppTrackingTransparency
import FirebaseAnalytics


class ViewController: UIViewController {
    
    let osb = OSB.instance
    var timer = Timer()
 
    override func viewDidAppear(_ animated: Bool) {
        intializeOSB()
    }
    
    func consentCallback(consent: [String: String]) -> Void {
        Analytics.setConsent(Dictionary(uniqueKeysWithValues: consent.map { t, s in (ConsentType(rawValue: t), ConsentStatus(rawValue: s)) }))
    }
    
    func intializeOSB() {
        print("intializeOSB()")
        // OSB configuration
        let accountId = "demo"
        let serverUrl = "https://c.onesecondbefore.com/"
        
        
        osb.config(accountId: accountId, url: serverUrl, siteId: "demo.app", consentCallback: consentCallback)
        osb.debug(true) // Enabling debug will print the JSON that is sent to the OSB server.
    }
    
    @IBAction func requestGoogleConsentModeButtonPressed(_ sender: UIButton) {
        if let consent = osb.getGoogleConsentModePayload() {
           print(Dictionary(uniqueKeysWithValues: consent.map { t, s in (ConsentType(rawValue: t), ConsentStatus(rawValue: s)) }))
        }
    }
    
    @IBAction func requestTrackingButtonPressed(_ sender: UIButton) {
        self.requestTrackingPermission()
    }
    
    @IBAction func requestLocationButtonPressed(_ sender: UIButton) {
        CLLocationManager().requestAlwaysAuthorization()
    }
    
    @IBAction func showCMPButtonPressed(_ sender: UIButton) {
        osb.showConsentWebview(parentView: self.view)
    }
    
    @IBAction func resurfaceCMPButtonPressed(_ sender: UIButton) {
        osb.showConsentWebview(parentView: self.view, forceShow: true)
    }

    @IBAction func sendExampleEventsButtonPressed(_ sender: UIButton) {
        do {
            
            print("TEST CASE 1")
            osb.setIds(data: [["key": "a3", "value": "12345"], ["key": "a3-1", "value": "12345-1"]])
//            TEST CASE 1
            osb.set(type: .page, data: [["id": 12334, "title" : "Onesecondbefore Homepage", "url": "https://www.onesecondbefore.com"]])
            try osb.send(type: .pageview)
            
//            TEST CASE 2
            print("TEST CASE 2")
            try osb.send(type: .viewable_impression, data: [["page_id": "11111", "campaign_id": 2]])
            
//            TEST CASE 3
            print("TEST CASE 3")
            try osb.sendPageView(url: "https://www.onesecondbefore.com/resources", title: "Onesecondbefore Resources", referrer: "https://www.onesecondbeforre.com", id:"3456");
            
            
//            TEST CASE 4
            print("TEST CASE 4")
            try osb.sendEvent(category: "unit_test", action: "unit_action", label:"unit_label", value:"8.9")
            
            
//            TEST CASE 5
            print("TEST CASE 5")
            try osb.sendScreenView(screenName:"screenName", className: "screenClass")
            
            
//            TEST CASE 6
            print("TEST CASE 6")
            try osb.sendEvent(category: "test after screenview", action: "some action", label:"some label", value: "8.9")
            
//            TEST CASE 7
            print("TEST CASE 7")
            osb.set(type: .item, data: [["id": "sku123", "name": "Apple iPhone 14 Pro", "category": "mobile", "price": 1234.56, "quantity": 1], ["id": "sku234", "name": "Samsung Galaxy S22", "category": "mobile", "price": 1034.56, "quantity": 1]])
            osb.set(type: .action, data: [["action": "purchase", "id": "abcd1234", "revenue": 2269.12, "tax": 2269.12 * 0.21, "shipping": 100, "affiliation": "partner_funnel"]])
            
            try osb.sendPageView(url: "https://www.onesecondbefore.com/thankyout.html", title: "Thank you purchase", referrer: "https://www.onesecondbefore.com/payment.html", id:"3456");

//            TEST CASE 8
            print("TEST CASE 8")
            try osb.sendAggregate(scope: "scope", name: "scrolldepth", aggregateType: OSBAggregateType.max, value: 0.8)


        } catch OSBError.notInitialised {
            print("OSB is not initialised")
        } catch {
            print("OSB error")
        }
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func requestTrackingPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    // Tracking authorization dialog was shown
                    // and we are authorized
                    print("Authorized to use IDFA:")
                    // Now that we are authorized we can get the IDFA
                    print(ASIdentifierManager.shared().advertisingIdentifier)
                case .denied:
                    // Tracking authorization dialog was
                    // shown and permission is denied
                    print("Denied to use IDFA")
                case .notDetermined:
                    // Tracking authorization dialog has not been shown
                    print("Authorization for using IDFA not yet determined.")
                case .restricted:
                    print("Use of IDFA is restricted on this device.")
                @unknown default:
                    print("IDFA authorization unknown,")
                }
            }
        }
    }
}
