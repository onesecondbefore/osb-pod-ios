//
//  JsonGenerator.swift
//  OSB
//
//  Created by Crypton on 04/06/19.
//  Copyright (c) 2023 Onesecondbefore B.V. All rights reserved.
//

import AdSupport
import AppTrackingTransparency
import UIKit

public class JsonGenerator {

    fileprivate var type: String = ""
    fileprivate var subType: String = ""
    fileprivate var data = [[String: Any]]()
    fileprivate var info: OSBInfo?
    fileprivate var latitude: Double = 0.0
    fileprivate var longitude: Double = 0.0
    fileprivate var isLocationEnabled: Bool = false
    fileprivate var eventKey: String = ""
    fileprivate var eventData: [String: Any]
    fileprivate var hitsData: [String: Any]
    fileprivate var viewId: String = ""
    fileprivate var consent: [String]?
    fileprivate var ids: [[String: Any]]?
    fileprivate var setDataObject: [String: Any]?

    // MARK: - Public functions

    init(_ type: String, data: [[String: Any]], info: OSBInfo?, subType: String,
         latitude: Double, longitude: Double, isLocEnabled: Bool,
         eventKey: String, eventData: [String: Any], hitsData: [String: Any],
         viewId: String, consent: [String]?, ids: [[String: Any]]?, setDataObject: [String: Any]?) {
        self.type = type
        self.data = data
        self.info = info
        self.subType = subType
        self.latitude = latitude
        self.longitude = longitude
        isLocationEnabled = isLocEnabled
        self.eventKey = eventKey
        self.eventData = eventData
        self.hitsData = hitsData
        self.viewId = viewId
        self.consent = consent
        self.ids = ids
        self.setDataObject = setDataObject
    }

    public func generateJsonResponse() -> String? {

        var jsonData: [String: Any] = [
            "sy": getSystemInfo(),
            "dv": getDeviceInfo(),
            "hits": [getHitsInfo()],
            "pg": getPageInfo(),
            "consent": getConsentInfo(),
            "ids": getIdsInfo(),
        ]

        if !eventKey.isEmpty && !eventData.isEmpty {
            jsonData[eventKey] = eventData
        }

        return dataToJson(jsonData)
    }

    // MARK: - Private functions

    fileprivate func getIdsInfo() -> Any {
        guard let ids = ids else {
            return NSNull()
        }

        return ids
    }

    fileprivate func getConsentInfo() -> Any {
        guard let consent = consent else {
            return NSNull()
        }

        return consent
    }

    fileprivate func getPageInfo() -> [String: Any] {
        let pvInfoData: [String: Any] = [
            "view_id": viewId,
        ]
        return pvInfoData
    }

    fileprivate func getSetDataForType(type: OSBSetType) -> [[String: Any]]? {
        return setDataObject?[type.rawValue] as? [[String: Any]]
    }

    fileprivate func getHitsInfo() -> [String: Any] {
        // Forms data and generate response
        var hitObj = [String: Any]()
        var dataObj = [String: Any]()

        // First add all appropriate data that was added with the set command. ^MB
        switch type {
        case OSBEventType.pageview.rawValue:
            if let pageData = getSetDataForType(type: OSBSetType.page) {
                for page in pageData {
                    for (key, value) in page {
                        dataObj[key] = value
                    }
                }
            }
            break
        case OSBEventType.event.rawValue:
            if let eventData = getSetDataForType(type: OSBSetType.event) {
                for event in eventData {
                    for (key, value) in event {
                        if isSpecialKey(key: key, eventType: OSBEventType.event) {
                            hitObj[key] = value
                        } else {
                            dataObj[key] = value
                        }
                    }
                }
            }
            break
        case OSBEventType.action.rawValue:
            if let actionData = getSetDataForType(type: OSBSetType.item) {
//                var itemsObject = [[String: Any]]()
//                for action in actionData {
//                    for (key, value) in action {
//                        itemsObject[key] = value
//                    }
//                }
//
//                if !itemsObject.isEmpty {
                hitObj["items"] = actionData
//                }
            }
            break
        case OSBEventType.viewable_impression.rawValue:
            if let viData = getSetDataForType(type: OSBSetType.viewable_impression) {
                for viewableImpression in viData {
                    for (key, value) in viewableImpression {
                        dataObj[key] = value
                    }
                }
            }
            break
        default:
            break
        }

        // Add/Overwrite all data that was added with the send command. ^MB
        for (key, value) in hitsData {
            dataObj[key] = value
        }

        hitObj["tp"] = type == "action" ? subType : getTypeIdentifier()
        hitObj["ht"] = dateToTimeStamp(Date())

        for object in data {
            for (key, value) in object {
                if let osbEventType = OSBEventType(rawValue: type), isSpecialKey(key: key, eventType: osbEventType) {
                    hitObj[key] = value
                } else {
                    dataObj[key] = value
                }
            }
        }

        hitObj["data"] = dataObj

        return hitObj
    }

    fileprivate func isSpecialKey(key: String, eventType: OSBEventType) -> Bool {
        switch eventType {
        case OSBEventType.event:
            return key == "category" || key == "value" || key == "label" || key == "action"
        case OSBEventType.aggregate:
            return key == "scope" || key == "name" || key == "value" || key == "aggregate"
        default:
            return false
        }
    }

    fileprivate func getSystemInfo() -> [String: Any] {
        // System info
        var namespace = "default"
        var accountId = "development"
        var siteId = ""
        if let info = info {
            if !info.namespaces.isEmpty {
                namespace = info.namespaces.joined(separator: ",")
            }

            accountId = info.accountId
            siteId = info.siteId ?? ""
        }

        let systemInfoData: [String: Any] = [
            "st": dateToTimeStamp(Date()),
            "tv": "6.0." + getGitHash(),
            "cs": 0,
            "is": hasValidGeoLocation() ? 0 : 1,
            "aid": accountId,
            "sid": siteId,
            "ns": namespace,
            "tt": "ios-post",
        ]

        return systemInfoData
    }

    fileprivate func getDeviceInfo() -> [String: Any] {
        // Device info
        let langId = NSLocale.current.languageCode ?? "nl"
        let countryId = NSLocale.current.regionCode ?? "NL"
        let lang = "\(langId)-\(countryId)"
        let idfa = getIDFA()

        let deviceInfoData: [String: Any] = [
            "idfa": idfa ?? NSNull(),
            "idfv": UIDevice.current.identifierForVendor!.uuidString,
            "tz": TimeZone.current.secondsFromGMT() / 60,
            "lang": lang,
            "conn": NetworkManager().getConnectionMode(),
            "sw": UIScreen.main.bounds.width,
            "sh": UIScreen.main.bounds.height,
            "mem": "\(totalDiskSpaceInBytes())",
        ]

        if hasValidGeoLocation() {
            let locationData = [
                "geo": [
                    "latitude": latitude,
                    "longitude": longitude,
                ],
            ]
            return deviceInfoData.merging(locationData) { current, _ in current }
        }

        return deviceInfoData
    }

    fileprivate func getModelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo)
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }

    fileprivate func getUsedDiskSpace() -> String {
        let usedSpaceInBytes = totalDiskSpaceInBytes() - freeDiskSpaceInBytes()
        if usedSpaceInBytes > 0 {
            return ByteCountFormatter.string(fromByteCount: usedSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.binary)
        }
        return ""
    }

    fileprivate func totalDiskSpaceInBytes() -> Int64 {
        do {
            guard let totalDiskSpaceInBytes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[FileAttributeKey.systemSize] as? Int64 else {
                return 0
            }
            return totalDiskSpaceInBytes
        } catch {
            return 0
        }
    }

    fileprivate func freeDiskSpaceInBytes() -> Int64 {
        do {
            guard let totalDiskSpaceInBytes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[FileAttributeKey.systemFreeSize] as? Int64 else {
                return 0
            }
            return totalDiskSpaceInBytes
        } catch {
            return 0
        }
    }

    fileprivate func dateToTimeStamp(_ date: Date) -> Int64 {
        return Int64(date.timeIntervalSince1970 * 1000)
    }

    fileprivate func dataToJson(_ dataDict: [String: Any]) -> String? {
        var jsonString: String? {
            do {
                let data: Data = try JSONSerialization.data(withJSONObject: dataDict, options: .prettyPrinted)
                return String(data: data, encoding: .utf8)
            } catch _ {
                return nil
            }
        }

        return jsonString
    }

    fileprivate func hasValidGeoLocation() -> Bool {
        return isLocationEnabled && latitude != 0.0 && longitude != 0.0
    }

    fileprivate func getTypeIdentifier() -> String {
        // Get the type of the hits
        if type == "screenview" {
            return "sv"
        } else if type == "pageview" {
            return "pageview"
        } else if type == "action" {
            return "ac"
        } else if type == "ids" {
            return "id"
        } else if type == "event" {
            return "event"
        } else if type == "aggregate" {
            return "aggregate"
        } else if type == "viewable_impression" {
            return "viewable_impression"
        }

        return "event"
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

    fileprivate func getGitHash() -> String {

        let frameworkBundle = Bundle(for: JsonGenerator.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("onesecondbefore-tracker.bundle")
        let resourceBundle = Bundle(url: bundleURL!)

        guard let path = resourceBundle?.path(forResource: "OSB", ofType: "plist"),
              let xml = FileManager.default.contents(atPath: path),
              let plist = try! PropertyListSerialization.propertyList(from: xml, options: .mutableContainers, format: nil) as? [String: String]
        else {
            return "unknown"
        }

        return plist["GitCommitHash"] ?? ""
    }
}
