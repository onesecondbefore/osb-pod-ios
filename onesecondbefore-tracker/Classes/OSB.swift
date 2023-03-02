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
    case ids
    case social
    case event
    case action
    case exception
    case pageview
    case screenview
    case timing
    case viewable_impression
    case aggregate
}

public enum OSBSetType: String {
    case action
    case event
    case item
    case page
    case viewable_impression
    case none
}

public enum OSBError: Error {
    case notInitialised
}

public enum OSBAggregateType: String {
    case max
    case min
    case count
    case sum
    case average = "avg"
}

public class OSB {

    // MARK: - Private variables

    fileprivate var info: OSBInfo = OSBInfo()
    fileprivate var locationManager = LocationManager()
    fileprivate var apiQueue: ApiQueue = ApiQueue()
    fileprivate var initialised: Bool = false
    fileprivate var eventKey: String = ""
    fileprivate var eventData: [String: Any] = [String: Any]()
    fileprivate var hitsData: [String: Any] = [String: Any]()
    fileprivate var viewId: String = ""
    fileprivate var ids: [[String: Any]] = [[String: Any]]()
    fileprivate var setDataObject = [String: Any]()

    // MARK: - Static variables

    static let UDConsentKey = "osb-defaults-consent"

    private init() {
        if viewId.isEmpty {
            viewId = generateRandomString()
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
    }()

    // MARK: - Public functions

    public func clear() {
        initialised = false
    }

    public func config(accountId: String, url: String) {
        config(accountId: accountId, url: url, siteId: "")
    }

    public func config(accountId: String, url: String, siteId: String) {
        clear()

        info.accountId = accountId
        info.siteId = siteId
        info.serverUrl = url

        initialised = true
    }

    public func debug(_ bDebugMode: Bool) {
        info.debugMode = bDebugMode
    }

    public func set(type: OSBSetType, data: [[String: Any]]) {
        setDataObject[type.rawValue] = data
    }

    public func set(data: [String: Any]) {
        hitsData = data
    }
    
    public func set(name: String, data: [String: Any]) {
        eventKey = name
        eventData = data
    }
    
    public func setIds(data: [String: Any]) {
        setIds(data: [data])
    }
    
    public func setIds(data: [[String: Any]]) {
        ids = data
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
        try sendEvent(category: category, action: "", label: "", value: "",
                      data: [String: Any]())
    }

    public func sendEvent(category: String, action: String) throws {
        try sendEvent(category: category, action: action, label: "", value: "",
                      data: [String: Any]())
    }

    public func sendEvent(category: String, action: String, label: String) throws {
        try sendEvent(category: category, action: action, label: label, value: "",
                      data: [String: Any]())
    }

    public func sendEvent(category: String, action: String, label: String, value: String) throws {
        try sendEvent(category: category, action: action, label: label, value: value,
                      data: [String: Any]())
    }

    public func sendEvent(category: String, action: String, label: String, value: String, data: [String: Any]) throws {
        hitsData = data
        var actionData = [String: Any]()

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

        try send(type: OSBEventType.event, data: [actionData])
    }

    public func sendAggregateEvent(scope: String, name: String, aggregateType: OSBAggregateType, value: Double) throws {
        var actionData = [String: Any]()
        if !scope.isEmpty {
            actionData["scope"] = scope
        }

        if !name.isEmpty {
            actionData["name"] = name
        }

        actionData["value"] = String(format: "%.1f", value)
        actionData["aggregate"] = aggregateType.rawValue

        try send(type: OSBEventType.aggregate, data: [actionData])
    }

    public func send(type: OSBEventType) throws {
        try send(type: type, actionType: "", data: [[String: Any]]())
    }

    public func send(type: OSBEventType, data: [[String: Any]]) throws {
        try send(type: type, actionType: "", data: data)
    }

    public func send(type: OSBEventType, actionType: String, data: [[String: Any]]) throws {
        if !initialised {
            throw OSBError.notInitialised
        }

        // Get location info
        let locationCoordinates = locationManager.getLocationCoordinates()
        let locationEnabled = locationManager.isLocationEnabled()

        // Generate the JSON data
        let generator = JsonGenerator(type.rawValue,
                                      data: data,
                                      info: info,
                                      subType: actionType,
                                      latitude: locationCoordinates.0,
                                      longitude: locationCoordinates.1,
                                      isLocEnabled: locationEnabled,
                                      eventKey: eventKey,
                                      eventData: eventData,
                                      hitsData: hitsData,
                                      viewId: viewId,
                                      consent: getConsent(),
                                      ids: ids,
                                      setDataObject: setDataObject)

        let jsonData = generator.generateJsonResponse()

        if info.debugMode { // Debug mode
            print(jsonData ?? "")
        }

        if let data = jsonData {
            // Add the response data to queue
            apiQueue.addToQueue(info.serverUrl, data: data)
        }
    }

    // MARK: - Deprecated functions

    @available(*, deprecated, renamed: "config")
    public func create(accountId: String, url: String) {
        create(accountId: accountId, url: url, siteId: "")
    }

    @available(*, deprecated, renamed: "config")
    public func create(accountId: String, url: String, siteId: String) {
        config(accountId: accountId, url: url, siteId: siteId)
    }

    @available(*, deprecated, message: "Please use send() with OSBEventType.pageview")
    public func sendPageView(url: String, title: String) throws {
        try sendPageView(url: url, title: title, referrer: "", data: [String: Any]())
    }

    @available(*, deprecated, message: "Please use send() with OSBEventType.pageview")
    public func sendPageView(url: String, title: String, referrer: String) throws {
        try sendPageView(url: url, title: title, referrer: referrer, data: [String: Any]())
    }

    @available(*, deprecated, message: "Please use send() with OSBEventType.pageview")
    public func sendPageView(url: String, title: String, referrer: String, data: [String: Any]) throws {
        var actionData: [String: Any] = data
        actionData["url"] = url
        actionData["ttl"] = title
        actionData["ref"] = referrer
        actionData["vid"] = viewId

        try send(type: OSBEventType.pageview, data: [actionData])
    }

    @available(*, deprecated, message: "Please use send(), you can specifiy screenname as property: data['sn'].")
    public func sendScreenView(screenName: String) throws {
        try sendScreenView(screenName: screenName, data: [String: Any]())
    }

    @available(*, deprecated, message: "Please use send(), you can specifiy screenname as property: data['sn'].")
    public func sendScreenView(screenName: String, data: [String: Any]) throws {
        var actionData: [String: Any] = data
        actionData["sn"] = screenName
        actionData["vid"] = viewId

        try send(type: OSBEventType.event, data: [actionData])
    }

    // MARK: - Private functions

    @objc private func applicationWillEnterForeground(_ notification: NSNotification) {
        viewId = generateRandomString()
    }

    private func generateRandomString(length: Int = 8) -> String {
        let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in alphabet.randomElement()! })
    }
}