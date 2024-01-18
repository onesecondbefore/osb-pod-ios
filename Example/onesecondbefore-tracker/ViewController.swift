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


class ViewController: UIViewController {
    
    let osb = OSB.instance
    var timer = Timer()
 
    override func viewDidAppear(_ animated: Bool) {
        self.requestTrackingPermission()
        CLLocationManager().requestAlwaysAuthorization()
        intializeOSB()
    }
    
    func intializeOSB() {
        // OSB configuration
        let accountId = "development"
        let serverUrl = "https://enbxr4mb0mcla.x.pipedream.net"
        osb.config(accountId: accountId, url: serverUrl, siteId: "osbdemo.app")

        osb.debug(true) // Enabling debug will print the JSON that is sent to the OSB server.
    }

    func sendExampleEvents() {

        do {
            // OSB - Aggregate event
            // JS: osb("send", "aggregate", "scrolledepth", "max", 0.8, "scope");
            //
            try osb.sendAggregate(scope: "scope", name: "scrolledepth", aggregateType: OSBAggregateType.max, value: 0.8)

            // OSB - Event
            // JS: osb("send", "event", { "category": "Category", "label": "Label", "action":"Action", "value": 1, "extra1": "a", "extra2": 3.1415});
            //
            // try osb.sendEvent(category: "Category", action: "Action", label: "Label", value: "1", data: [["extra1": "a", "extra2": 3.1415]])

            // OSB - IDS
            // JS: osb("set", "ids", [{ "key": "a3", "value": "12345"}]);
            // JS: osb("send", "pageview");
            //
             osb.setIds(data: [["key": "a3", "value": "12345"], ["key": "a3-1", "value": "12345-1"]])
            // try osb.send(type: .pageview)

            // OSB - CONSENT + page data
            // JS: osb.setConsent(["marketing", "social", "functional", "advertising"]);
            // JS: osb.set("page", {"article": 123})
            // JS: osb.send("pageview", {"b": 2});
            //
//            osb.setConsent(data: ["marketing", "social", "functional", "advertising"])
            osb.set(type: .page, data: [["article": 123, "oss_category" : "OSS category"]])
            try osb.send(type: .pageview, data: [["b": 2]])
            try osb.send(type: .pageview)

            // OSB - VIEWABLE IMPRESSION
            //
            try osb.send(type: .viewable_impression, data: [["a": 1, "b": 2]])

            // OSB - ACTION
            // JS: osb('set', 'items', [{id: 'sku123',name: 'Apple iPhone 14 Pro',category: 'mobile',price: 1234.56,quantity: 1}, {id: 'sku234',name: 'Samsung Galaxy S22',category: 'mobile',price: 1034.56,quantity: 1}])
            // JS: osb('send', 'action', 'purchase', { id: 'abcd1234', revenue: 2269.12, tax: (2269.12 * 0.21), shipping: 100, affiliation: 'partner_funnel')}
            //
            // osb.set(type: .item, data: [["id": "sku123", "name": "Apple iPhone 14 Pro", "category": "mobile", "price": 1234.56, "quantity": 1], ["id": "sku234", "name": "Samsung Galaxy S22", "category": "mobile", "price": 1034.56, "quantity": 1]])
            try osb.send(type: .action, actionType: "purchase", data: [["id": "abcd1234", "revenue": 2269.12, "tax": 2269.12 * 0.21, "shipping": 100, "affiliation": "partner_funnel"]])

            // OSB - Screen view
            try osb.sendScreenView(screenName: "Homepage", className: "MainController", data: ["a": "1", "b": "2"])

        } catch OSBError.notInitialised {
            print("OSB is not initialised")
        } catch {
            print("OSB error")
        }
    }
    
    @IBAction func showConsentWebviewButtonPressed(_ sender: UIButton) {
        osb.showConsentWebview(parentView: self.view)
    }
    
    @IBAction func forceConsentWebviewButtonPressed(_ sender: UIButton) {
        osb.showConsentWebview(parentView: self.view, forceShow: true)
    }
    
    @IBAction func requestTrackingButtonPressed(_ sender: UIButton) {
        self.requestTrackingPermission()
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
                    print("Authorized")

                    // Now that we are authorized we can get the IDFA
                    print(ASIdentifierManager.shared().advertisingIdentifier)
                case .denied:
                    // Tracking authorization dialog was
                    // shown and permission is denied
                    print("Denied")
                case .notDetermined:
                    // Tracking authorization dialog has not been shown
                    print("Not Determined")
                case .restricted:
                    print("Restricted")
                @unknown default:
                    print("Unknown")
                }
            }
        }
    }
}
