//
//  OSB.swift
//
//  Copyright (c) 2023 Onesecondbefore B.V. All rights reserved.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import WebKit
import AppTrackingTransparency
import AdSupport
import CommonCrypto
import CryptoKit

public enum OSBHitType: String {
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

public class OSB: NSObject {
    
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
    fileprivate var consentCallback: (([String:String]) -> Void)?
    
    // MARK: - Static variables
    static let UDConsentKey = "osb-defaults-consent"
    static let UDConsentExpirationKey = "osb-defaults-consent-exp"
    static let UDCDUIDKey = "osb-defaults-cduid"
    static let UDLocalCMPVersionKey = "osb-defaults-local-cmp-version"
    static let UDRemoteCMPVersionKey = "osb-defaults-remote-cmp-version"
    static let UDCmpCheckTimestampKey = "osb-defaults-cmp-check-timestamp"
    static let UDGoogleConsentModeKey = "osb-defaults-google-consent-mode"
    
    private override init() {
        super.init()
        if viewId.isEmpty {
            viewId = generateRandomString()
        }
        
        // link to osbCmpMessageHandler callback from consent webview. ^MB
        let contentController = self.osbConsentWebview.configuration.userContentController
        contentController.add(self, name: "osbCmpMessageHandler")
    }
    
    public static let instance: OSB = {
        let instance = OSB()
        return instance
    }()
    
    // MARK: - Public functions
    
    public func showConsentWebview(parentView: UIView, forceShow: Bool = false) {
        if (forceShow || shouldShowConsentWebview()){
            if let url = getConsentWebviewURL() {
                parentView.addSubview(osbConsentWebview)
                
                NSLayoutConstraint.activate([
                    osbConsentWebview.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                    osbConsentWebview.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                    osbConsentWebview.bottomAnchor.constraint(equalTo: parentView.layoutMarginsGuide.bottomAnchor),
                    osbConsentWebview.topAnchor.constraint(equalTo: parentView.layoutMarginsGuide.topAnchor)
                ])
                
                osbConsentWebview.load(URLRequest(url: url))
            }
        }
    }
    
    private lazy var osbConsentWebview: WKWebView = {
        let osbConsentWebview = WKWebView()
        osbConsentWebview.translatesAutoresizingMaskIntoConstraints = false
        return osbConsentWebview
    }()
    
    func hideConsentWebview() {
        osbConsentWebview.removeFromSuperview()
    }
    
    public func clear() {
        initialised = false
    }
    
    public func config(accountId: String, url: String, siteId: String, consentCallback: (([String:String]) -> Void)?) {
        
        self.consentCallback = consentCallback
        clear()
        
        info.accountId = accountId
        info.siteId = siteId
        info.serverUrl = url
        
        fetchRemoteCmpVersion()
        
        locationManager.initialize()
        
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
        try sendEvent(category: category, action: action, label: label, value: value, data: data, interaction: nil)
    }
    
    
    public func sendEvent(category: String, action: String, label: String, value: String, data: [String: Any], interaction: Bool?) throws {
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
        
        if let interaction = interaction {
            actionData["interaction"] = String(interaction)
        }
        
        try send(type: OSBHitType.event, data: [actionData])
    }
    
    public func sendAggregate(scope: String, name: String, aggregateType: OSBAggregateType, value: Double) throws {
        var actionData = [String: Any]()
        if !scope.isEmpty {
            actionData["scope"] = scope
        }
        
        if !name.isEmpty {
            actionData["name"] = name
        }
        
        actionData["value"] = String(format: "%.1f", value)
        actionData["aggregate"] = aggregateType.rawValue
        
        try send(type: OSBHitType.aggregate, data: [actionData])
    }
    
    public func sendScreenView(screenName: String) throws {
        try sendScreenView(screenName: screenName, className: "", data: [:])
    }
    
    public func sendScreenView(screenName: String, data: [String: Any]) throws {
        try sendScreenView(screenName: screenName, className: "", data: data)
    }
    
    public func sendScreenView(screenName: String, className: String) throws {
        try sendScreenView(screenName: screenName, className: className, data: [:])
    }
    
    public func sendScreenView(screenName: String, className: String, data: [String: Any]) throws {
        var actionData: [String: Any] = data
        actionData["sn"] = screenName
        actionData["cn"] = className
        remove(type: "page");
        try send(type: OSBHitType.screenview, data: [actionData])
    }
    
    public func sendPageView(url: String, title: String) throws {
        try sendPageView(url: url, title: title, referrer: "", data: [String: Any]())
    }
    
    public func sendPageView(url: String, title: String, referrer: String) throws {
        try sendPageView(url: url, title: title, referrer: referrer, data: [String: Any]())
    }
    
    public func sendPageView(url: String, title: String, referrer: String, id: String) throws {
        try sendPageView(url: url, title: title, referrer: referrer, data: [String: Any]())
    }
    
    public func sendPageView(url: String, title: String, referrer: String, data: [String: Any]) throws {
        try sendPageView(url: url, title: title, referrer: referrer, data: data, id: "")
    }
    
    public func sendPageView(url: String, title: String, referrer: String, data: [String: Any], id: String) throws {
        try sendPageView(url: url, title: title, referrer: referrer, data: data, id: id, osc_id: "", osc_label: "", oss_keyword: "", oss_category: "", oss_total_results: "", oss_results_per_page: "", oss_current_page: "")
    }
    
    public func sendPageView(url: String, title: String, referrer: String, data: [String: Any], id: String, osc_id: String, osc_label: String, oss_keyword: String, oss_category: String, oss_total_results: String, oss_results_per_page: String, oss_current_page: String) throws {
        var actionData: [String: Any] = data
        actionData["url"] = url
        actionData["title"] = title
        actionData["ref"] = referrer
        actionData["id"] = id
        actionData["osc_id"] = osc_id
        actionData["osc_label"] = osc_label
        actionData["oss_keyword"] = oss_keyword
        actionData["oss_category"] = oss_category
        actionData["oss_total_results"] = oss_total_results
        actionData["oss_results_per_page"] = oss_results_per_page
        actionData["oss_current_page"] = oss_current_page
        
        
        try send(type: OSBHitType.pageview, data: [actionData])
        
        // Store data object for next send() ^MB
        set(type: .page, data: [actionData]);
    }
    
    public func send(type: OSBHitType) throws {
        try send(type: type, actionType: "", data: [[String: Any]]())
    }
    
    public func send(type: OSBHitType, data: [String: Any]) throws {
        try send(type: type, actionType: "", data: [data])
    }
    
    public func send(type: OSBHitType, data: [[String: Any]]) throws {
        try send(type: type, actionType: "", data: data)
    }
    
    public func send(type: OSBHitType, actionType: String, data: [[String: Any]]) throws {
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
                                      viewId: getViewId(type: type),
                                      consent: getConsent(),
                                      ids: ids,
                                      setDataObject: setDataObject,
                                      idfa: getIDFA(),
                                      idfv: getIDFV(),
                                      cduid: getCDUID())
        
        
        let jsonData = generator.generateJsonResponse()
        
        removeHitScope()
        
        if info.debugMode { // Debug mode
            print(jsonData ?? "")
        }
        
        if let data = jsonData {
            // Add the response data to queue
            apiQueue.addToQueue(info.serverUrl, data: data)
        }
    }
    
    public func remove() {
        remove(type: "action")
        remove(type: "event")
        remove(type: "item")
        remove(type: "page")
        remove(type: "hits")
        remove(type: "ids")
    }
    
    public func remove(type: String) {
        switch type {
        case "action":
            set(type: .action, data: [[String: Any]]())
            break
        case "event":
            eventData = [String: Any]()
            break
        case "item":
            set(type: .item, data: [[String: Any]]())
            break
        case "page":
            set(type: .page, data: [[String: Any]]())
            break
        case "hits":
            hitsData = [String: Any]()
            break
        case "ids":
            ids = [[String: Any]]()
            break
        default:
            break
        }
    }
    
    public func shouldResurfaceCmp() -> Bool {
        if let remoteCmpVersion = getRemoteCmpVersion() {
            if let localCmpVersion = getLocalCmpVersion(), remoteCmpVersion <= localCmpVersion {
                return false
            }
            setLocalCmpVersion(cmpVersion: remoteCmpVersion)
            return true
        }
        return false
    }
    
    public func getGoogleConsentModePayload() -> [String:String]? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: OSB.UDGoogleConsentModeKey) as? [String:String]
    }
    
    // MARK: - Deprecated functions
    
    @available(*, deprecated, renamed: "OSBHitType")
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
    
    @available(*, deprecated, renamed: "config")
    public func create(accountId: String, url: String) {
        create(accountId: accountId, url: url, siteId: "")
    }
    
    @available(*, deprecated, renamed: "config")
    public func create(accountId: String, url: String, siteId: String) {
        config(accountId: accountId, url: url, siteId: siteId, consentCallback: nil)
    }
    
    @available(*, deprecated, renamed: "remove")
    public func reset() {
        remove()
    }
    
    // MARK: - Private functions
    
    private func getViewId(type: OSBHitType) -> String {
        if type == .pageview || type == .screenview {
            viewId = generateRandomString()
        }
        
        return viewId
    }
    
    private func generateRandomString(length: Int = 8) -> String {
        let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in alphabet.randomElement()! })
    }
    
    private func removeHitScope() {
        eventData = [String: Any]()
        hitsData = [String: Any]()
        ids = [[String: Any]]()
        set(type: .item, data: [[String: Any]]())
        set(type: .action, data: [[String: Any]]())
        
        let pageData = setDataObject["page"] as? [[String: Any]]
        if var page = pageData?.first {
            page["oss_category"] = nil;
            page["oss_keyword"] = nil;
            page["oss_total_results"] = nil;
            page["oss_results_per_page"] = nil;
            page["oss_current_page"] = nil;
            page["osc_id"] = nil;
            
            // Should these two be implemented as well? ^MB
            page["onsite_search"] = nil;
            page["onsite_campaign"] = nil;
            
            set(type: .page, data: [page])
        }
    }
    
    private func stringify(json: Any, prettyPrinted: Bool = false) -> String {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
            options = JSONSerialization.WritingOptions.prettyPrinted
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: options)
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                return string
            }
        } catch {
            print(error)
        }
        
        return ""
    }
    
    fileprivate func getUserUID() -> String {
        if let cduid = getCDUID() {
            return cduid
        }
        
        if let idfa = getIDFA(), idfa != "00000000-0000-0000-0000-000000000000" {
            return idfa
        }
        
        if let idfv = getIDFV() {
            return idfv
        }
        
        print("OSB Error: could not get userUID")
        
        return ""
    }
    
    fileprivate func getIDFA() -> String? {
        // Check whether advertising tracking is enabled
        if #available(iOS 14, *) {
            if ATTrackingManager.trackingAuthorizationStatus != ATTrackingManager.AuthorizationStatus.authorized {
                return nil
            }
        } else {
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled == false {
                return nil
            }
        }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    fileprivate func getIDFV() -> String? {
        if let identifierForVendor = UIDevice.current.identifierForVendor {
            return identifierForVendor.uuidString
        }
        return nil
    }
    
    fileprivate func getConsentWebviewURL() -> URL? {
        var consent = "";
        if let consentString = getConsent()?.first {
            consent = consentString
        }
        
        var siteIdURL = "";
        if let siteId = info.siteId {
            siteIdURL = "&sid=" + siteId
        }
        
        let urlString = info.serverUrl + "/consent?aid=" + info.accountId + siteIdURL + "&type=app&show=true&version=" + getOSBSDKVersion() + "&consent=" + consent + "&cduid=" + getUserUID()
        
        return URL(string: urlString)
    }
    
    fileprivate func processConsentCallback(consentCallbackString: String) {
        hideConsentWebview()
        if let json = convertConsentCallbackToJSON(consentCallbackString: consentCallbackString) {
            if let jsonConsent = json["consent"] as? Dictionary<String, Any>, let consentString = jsonConsent["tcString"] as? String, let expirationDate = json["expirationDate"] as? Int, let cduid = json["cduid"] as? String, let purposes = jsonConsent["purposes"] as? [Int] {
                
                
                let consentMode = mapConsentMode(purposes: purposes)
                setGoogleConsentMode(consent: consentMode)
                if let cc = self.consentCallback {
                    cc(consentMode)
                }
                
                decodeAndStoreIABConsent(consentString: consentString)
                setConsent(data: consentString)
                setConsentExpiration(timestamp: expirationDate)
                setCDUID(cduid: cduid)
            }
        }
    }
    
    fileprivate func mapConsentMode(purposes: [Int]) -> [String: String]{
 
        var consent = ["ad_storage": "denied", "ad_user_data": "denied", "ad_personalization": "denied", "analytics_storage": "granted", "functionality_storage": "granted", "personalization_storage": "granted", "security_storage": "granted"]
        
        if purposes.contains(1) {
            consent["ad_storage"] = "granted"
        }
        
        if purposes.contains(1) && purposes.contains(7) {
            consent["ad_user_data"] = "granted"
        }
        
        if purposes.contains(3) && purposes.contains(4) {
            consent["ad_personalization"] = "granted"
        }
        
        return consent
    }
    
    fileprivate func convertConsentCallbackToJSON(consentCallbackString: String) -> Dictionary<String, Any>? {
        let data = consentCallbackString.data(using: .utf8)!
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? Dictionary<String, Any>
            {
                return json
            } else {
                print("OSB Error: Could not parse consentCallbackString to JSON.")
            }
        } catch let error as NSError {
            print(error)
        }
        return nil
    }
    
    fileprivate func getOSBSDKVersion() -> String {
        if let version = Bundle(identifier: "org.cocoapods.onesecondbefore-tracker")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version;
        }
        
        return "unknown"
    }
    
    fileprivate func setConsentExpiration(timestamp: Int) {
        let defaults = UserDefaults.standard
        defaults.set(timestamp, forKey: OSB.UDConsentExpirationKey)
    }
    
    fileprivate func getConsentExpiration() -> Int? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: OSB.UDConsentExpirationKey) as? Int
    }
    
    fileprivate func shouldShowConsentWebview() -> Bool {
        if shouldResurfaceCmp() {
            return true
        }
        
        if let expirationDate = getConsentExpiration(), expirationDate > Int(NSDate().timeIntervalSince1970) * 1000 {
            return false
        }
        
        return true
    }
    
    fileprivate func setCDUID(cduid: String) {
        let defaults = UserDefaults.standard
        defaults.set(cduid, forKey: OSB.UDCDUIDKey)
    }
    
    fileprivate func getCDUID() -> String? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: OSB.UDCDUIDKey) as? String
    }
    
    fileprivate func setRemoteCmpVersion(cmpVersion: Int) {
        let defaults = UserDefaults.standard
        defaults.set(cmpVersion, forKey: OSB.UDRemoteCMPVersionKey)
        defaults.set(Int(NSDate().timeIntervalSince1970), forKey: OSB.UDCmpCheckTimestampKey)
    }
    
    fileprivate func getRemoteCmpVersion() -> Int? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: OSB.UDRemoteCMPVersionKey) as? Int
    }
    
    fileprivate func setLocalCmpVersion(cmpVersion: Int) {
        let defaults = UserDefaults.standard
        defaults.set(cmpVersion, forKey: OSB.UDLocalCMPVersionKey)
    }
    
    fileprivate func getLocalCmpVersion() -> Int? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: OSB.UDLocalCMPVersionKey) as? Int
    }
    
    fileprivate func getCmpCheckTimestamp() -> Int? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: OSB.UDCmpCheckTimestampKey) as? Int
    }
    
    fileprivate func processFetchedCmpResponse(cmpResponseData: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: cmpResponseData, options: []) as? [String: Any] {
                if let cmpVersion = json["cmpVersion"] as? Int {
                    setRemoteCmpVersion(cmpVersion: cmpVersion)
                } else {
                    print("OSB Error: Could not get cmpVersion from JSON.")
                }
            }
        } catch {
            print("OSB Error: Could not parse cmpResponseData.")
            print(error.localizedDescription)
        }
    }
    
    fileprivate func fetchRemoteCmpVersion() {
        guard let cmpCheckTimestamp = getCmpCheckTimestamp() else {
            requestRemoteCmpVersion()
            return
        }
        
        if (cmpCheckTimestamp + (24 * 60 * 60) < Int(NSDate().timeIntervalSince1970)){
            requestRemoteCmpVersion()
        }
    }
    
    fileprivate func requestRemoteCmpVersion() {
        guard let url = URL(string: getCmpVersionUrl()) else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                self.processFetchedCmpResponse(cmpResponseData: data)
            } else if let error = error {
                print("OSB error: requestRemoteCmpVersion() - HTTP Request Failed \(error)")
            }
        }
        
        task.resume()
    }
    
    fileprivate func getCmpVersionUrl() -> String {
        if let siteId = info.siteId {
            let string = info.accountId + "-" + siteId;
            let hexDigest = String(string.data(using: .ascii)!.sha1)
            let index = string.index(string.startIndex, offsetBy: 8)
            return "https://cdn.onesecondbefore.com/cmp/" + String(hexDigest[..<index]) + ".json";
        } else {
            print("OSB error: getCmpVersionUrl() - siteId unknown.")
        }
        return ""
    }
    
    fileprivate func decodeAndStoreIABConsent(consentString: String) {
        SPTIabTCFApi().consentString = consentString
    }
    
    fileprivate func setGoogleConsentMode(consent: [String:String]) {
        let defaults = UserDefaults.standard
        defaults.set(consent, forKey: OSB.UDGoogleConsentModeKey)
    }
    
    fileprivate func printAllUD() {
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            print("\(key) = \(value) \n")
        }
    }
}

extension OSB: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let consentCallbackString = message.body as? String {
            processConsentCallback(consentCallbackString: consentCallbackString)
        } else {
            print("OSB error: could not parse consent callback string.")
        }
    }
}

private func hexString(_ iterator: Array<UInt8>.Iterator) -> String {
    return iterator.map { String(format: "%02x", $0) }.joined()
}

extension Data {
    
    public var sha1: String {
        if #available(iOS 13.0, *) {
            return hexString(Insecure.SHA1.hash(data: self).makeIterator())
        } else {
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
            self.withUnsafeBytes { bytes in
                _ = CC_SHA1(bytes.baseAddress, CC_LONG(self.count), &digest)
            }
            return hexString(digest.makeIterator())
        }
    }
    
}

