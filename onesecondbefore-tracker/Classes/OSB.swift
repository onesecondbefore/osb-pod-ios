//
//  OSB.swift
//  OSB
//
//  Created by Crypton on 04/06/19.
//  Copyright © 2019 Crypton. All rights reserved.
//

import Foundation
import UIKit

public enum OSBEventType: String {
    case ids = "ids"
    case social = "social"
    case event = "event"
    case action = "action"
    case exception = "exception"
    case pageview = "pageview"
    case screenview = "screenview"
    case timing = "timing"
    case viewable_impression = "viewable_impression"
    case aggregate = "aggregate"
}

public enum OSBError: Error {
    case notInitialised
}

public enum OSBAggregateType: String {
    case max = "max"
    case min = "min"
    case count = "count"
    case sum = "sum"
    case average = "avg"
}

public class OSB {
    
    // MARK: - Private variables
    fileprivate var info: OSBInfo = OSBInfo()
    fileprivate var locationManager =  LocationManager()
    fileprivate var apiQueue: ApiQueue = ApiQueue()
    fileprivate var initialised: Bool = false
    fileprivate var eventKey: String = ""
    fileprivate var eventData: [String: Any] = [String: Any]()
    fileprivate var hitsData: [String: Any] = [String: Any]()
    fileprivate var viewId: String = ""
    
    // MARK: - Static variables
    static let UDConsentKey = "osb-defaults-consent"
    
    private init() {
        if (self.viewId.isEmpty){
            self.viewId = generateRandomString()
        }
        
        // Listen to life cycle notification to reset viewId.
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(applicationWillEnterForeground(_:)),
          name: UIApplication.willEnterForegroundNotification,
          object: nil)
    }
    
    public static let instance: OSB = {
        let instance = OSB()
        return instance
    } ()
    
    // MARK: - Public functions
    
    public func clear() {
        self.initialised = false
    }
    
    public func config(accountId: String, url: String) {
        self.config(accountId: accountId, url: url, siteId: "")
    }
    
    public func config(accountId: String, url: String, siteId: String) {
        self.clear()
        
        self.info.accountId = accountId
        self.info.siteId = siteId
        self.info.serverUrl = url

        self.initialised = true
    }

    public func debug(_ bDebugMode: Bool) {
        self.info.debugMode = bDebugMode
    }
    
    public func set(name: String, data: [String: Any]) {
        self.eventKey = name
        self.eventData = data
    }
    
    public func set(data: [String: Any]) {
        self.hitsData = data
    }
    
    public func setConsent(data: String) {
        setConsent(data: [data])
    }
    
    public func setConsent(data: [String]) {
        let defaults = UserDefaults.standard
        defaults.set(data, forKey: OSB.UDConsentKey)
    }
    
    public func getConsent() -> [String]? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: OSB.UDConsentKey) as? [String]
    }
    
    public func sendEvent(category: String) throws {
        try self.sendEvent(category: category, action: "", label: "", value: "",
                       data: [String: Any]())
    }
    
    public func sendEvent(category: String, action: String) throws {
        try self.sendEvent(category: category, action: action, label: "", value: "",
                       data: [String: Any]())
    }
    
    public func sendEvent(category: String, action: String, label: String) throws {
        try self.sendEvent(category: category, action: action, label: label, value: "",
                       data: [String: Any]())
    }
    
    public func sendEvent(category: String, action: String, label: String, value: String) throws {
        try self.sendEvent(category: category, action: action, label: label, value: value,
                       data: [String: Any]())
    }
    
    public func sendEvent(category: String, action: String, label: String, value: String,
                          data: [String: Any]) throws {
        var actionData:[String: Any] = data
        if !category.isEmpty {
            actionData["category"] = category
        }
        
        if !action.isEmpty {
            actionData["action"] = action
        }
        
        if !label.isEmpty {
            actionData["label"] = label
        }
        
        if !value.isEmpty {
            actionData["value"] = value
        }
        
        try self.send(type: OSBEventType.event, data: actionData);
    }
    
    public func sendAggregateEvent(scope: String, name: String, aggregateType: OSBAggregateType, value: Double) throws {
        var actionData = [String: Any]()
        if !scope.isEmpty {
            actionData["scope"] = scope
        }
        
        if !name.isEmpty {
            actionData["name"] = name
        }
        
        actionData["value"] = String (format: "%.1f", value)
        actionData["type"] = aggregateType.rawValue

        try self.send(type: OSBEventType.aggregate, data: actionData);
    }
    
    public func send(type: OSBEventType) throws {
        try self.send(type: type, actionType: "", data: [String: Any]())
    }
    
    public func send(type: OSBEventType, data: [String: Any]) throws {
        try self.send(type: type, actionType: "", data: data)
    }
    
    public func send(type: OSBEventType, actionType: String, data: [String: Any]) throws {
        if (!self.initialised) {
            throw OSBError.notInitialised
        }

        // Get location info
        let locationCoordinates = self.locationManager.getLocationCoordinates()
        let locationEnabled = self.locationManager.isLocationEnabled()
        
        // Generate the JSON data
        let generator = JsonGenerator(type.rawValue,
                                      data: data,
                                      info: self.info,
                                      subType: actionType,
                                      latitude: locationCoordinates.0,
                                      longitude: locationCoordinates.1,
                                      isLocEnabled: locationEnabled,
                                      eventKey: self.eventKey,
                                      eventData: self.eventData,
                                      hitsData: self.hitsData,
                                      viewId: self.viewId,
                                      consent: self.getConsent())
        
        let jsonData = generator.generateJsonResponse()
        
        if (self.info.debugMode) { // Debug mode
            print(jsonData ?? "")
        }
        
        if let data = jsonData {
           // Add the response data to queue
            self.apiQueue.addToQueue(self.info.serverUrl, data: data)
        }
    }
    
    
    // MARK: - Deprecated functions
    
    @available(*, deprecated, renamed: "config")
    public func create(accountId: String, url: String) {
        self.create(accountId: accountId, url: url, siteId: "")
    }
    
    @available(*, deprecated, renamed: "config")
    public func create(accountId: String, url: String, siteId: String) {
        self.config(accountId: accountId, url: url, siteId: siteId)
    }
    
    @available(*, deprecated, message: "Please use send() with OSBEventType.pageview")
    public func sendPageView(url: String, title: String) throws {
        try self.sendPageView(url: url, title: title, referrer: "", data: [String: Any]())
    }
    
    @available(*, deprecated, message: "Please use send() with OSBEventType.pageview")
    public func sendPageView(url: String, title: String, referrer: String) throws {
        try self.sendPageView(url: url, title: title, referrer: referrer, data: [String: Any]())
    }
    
    @available(*, deprecated, message: "Please use send() with OSBEventType.pageview")
    public func sendPageView(url: String, title: String, referrer: String, data: [String: Any]) throws {
        var actionData:[String: Any] = data
        actionData["url"] = url
        actionData["ttl"] = title
        actionData["ref"] = referrer
        actionData["vid"] = self.viewId
        
        try self.send(type: OSBEventType.pageview, data: actionData);
    }
    
    @available(*, deprecated, message: "Please use send(), you can specifiy screenname as property: data['sn'].")
    public func sendScreenView(screenName: String) throws {
        try self.sendScreenView(screenName: screenName, data: [String: Any]())
    }
    
    @available(*, deprecated, message: "Please use send(), you can specifiy screenname as property: data['sn'].")
    public func sendScreenView(screenName: String, data: [String: Any]) throws {
        var actionData:[String: Any] = data
        actionData["sn"] = screenName
        actionData["vid"] = self.viewId
        
        try self.send(type: OSBEventType.event, data: actionData);
    }
    
    // MARK: - Private functions
    @objc private func applicationWillEnterForeground(_ notification: NSNotification) {
        self.viewId = generateRandomString()
    }
    
    private func generateRandomString(length: Int = 8) -> String {
        let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in alphabet.randomElement()! })
    }
}
