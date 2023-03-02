//
//  ViewController.swift
//  onesecondbefore-tracker
//
//  Created by MartienB on 03/01/2023.
//  Copyright (c) 2023 MartienB. All rights reserved.
//

import UIKit
import onesecondbefore_tracker

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // OSB configuration
        let osb = OSB.instance
        let clientId =  "ios_sdk-defdf0691b47bea99f6d7db2ce2b6b83a9fbd53a"
        let serverUrl = "https://enbxr4mb0mcla.x.pipedream.net"
        osb.config(accountId: clientId, url: serverUrl, siteId: "osbdemo.app")
        
        osb.debug(true) // Enabling debug will print the JSON that is send to the OSB server.
        
        // OSB - setting consent
        osb.setConsent(data: ["marketing", "social", "functional", "advertising"]);
        // or
        osb.setConsent(data: "consent-string-identifier-1234-abcd");
        
        
        do {
            // OSB - Aggregate event
            // JS: osb("send", "aggregate", "scrolledepth", "max", 0.8, "scope");
            //
             try osb.sendAggregateEvent(scope: "scope", name: "scrolledepth", aggregateType: OSBAggregateType.max, value: 0.8)
            
            // OSB - Event
            // JS: osb("send", "event", { "category": "Category", "label": "Label", "action":"Action", "value": 1, "extra1": "a", "extra2": 3.1415});
            //
            // try osb.sendEvent(category: "Category", action: "Action", label: "Label", value: "1", data: [["extra1": "a", "extra2": 3.1415]])
            
            // OSB - IDS
            // JS: osb("set", "ids", [{ "key": "a3", "value": "12345"}]);
            // JS: osb("send", "pageview");
            //
            // osb.setIds(data: [["key": "a3", "value": "12345"], ["key": "a3-1", "value": "12345-1"]])
            // try osb.send(type: .pageview)
            
            // OSB - CONSENT + page data
            // JS: osb.setConsent(["marketing", "social", "functional", "advertising"]);
            // JS: osb.set("page", {"article": 123})
            // JS: osb.send("pageview", {"b": 2});
            //
            // osb.setConsent(data: ["marketing", "social", "functional", "advertising"]);
            // osb.set(type: .page, data: [["article": 123]])
            // try osb.send(type: .pageview, data: [["b": 2]])
            // try osb.send(type: .pageview)
            
            // OSB - VIEWABLE IMPRESSION
            //
            // try osb.send(type: .viewable_impression, data: [["a": 1, "b": 2]])
            
            // OSB - ACTION
            // JS: osb('set', 'items', [{id: 'sku123',name: 'Apple iPhone 14 Pro',category: 'mobile',price: 1234.56,quantity: 1}, {id: 'sku234',name: 'Samsung Galaxy S22',category: 'mobile',price: 1034.56,quantity: 1}])
            // JS: osb('send', 'action', 'purchase', { id: 'abcd1234', revenue: 2269.12, tax: (2269.12 * 0.21), shipping: 100, affiliation: 'partner_funnel')}
            //
            // osb.set(type: .item, data: [["id": "sku123", "name": "Apple iPhone 14 Pro", "category": "mobile", "price": 1234.56, "quantity": 1], ["id": "sku234", "name": "Samsung Galaxy S22", "category": "mobile", "price": 1034.56, "quantity": 1]])
            // try osb.send(type: .action, actionType: "purchase", data: [["id": "abcd1234", "revenue": 2269.12, "tax": (2269.12 * 0.21), "shipping": 100, "affiliation": "partner_funnel"]])
            
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
}

