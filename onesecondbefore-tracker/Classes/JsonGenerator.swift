//
//  JsonGenerator.swift
//  OSB
//
//  Created by Crypton on 04/06/19.
//  Copyright © 2019 Crypton. All rights reserved.
//

import UIKit
import AppTrackingTransparency
import AdSupport


public class JsonGenerator {
    
    fileprivate var type: String = ""
    fileprivate var subType: String = ""
    fileprivate var data = [String: Any]()
    fileprivate var info: OSBInfo? = nil
    fileprivate var latitude: Double = 0.0
    fileprivate var longitude: Double = 0.0
    fileprivate var isLocationEnabled: Bool = false
    fileprivate var eventKey: String = ""
    fileprivate var eventData: [String: Any]
    fileprivate var hitsData: [String: Any]
    fileprivate var viewId: String = ""
    fileprivate var consent: [String]?
    
    // MARK: - Public functions
    
    init(_ type: String, data: [String: Any], info: OSBInfo?, subType: String,
                latitude: Double, longitude: Double, isLocEnabled: Bool,
         eventKey: String, eventData: [String: Any], hitsData: [String: Any], viewId: String, consent: [String]? ) {
        self.type = type
        self.data = data
        self.info = info
        self.subType = subType
        self.latitude = latitude
        self.longitude = longitude
        self.isLocationEnabled = isLocEnabled
        self.eventKey = eventKey
        self.eventData = eventData
        self.hitsData = hitsData
        self.viewId = viewId
        self.consent = consent
    }
    
    public func generateJsonResponse() -> String? {
 
        var jsonData: [String: Any] = [
            "sy" : self.getSystemInfo(),
            "dv": self.getDeviceInfo(),
            "hits": [self.getHitsInfo()],
            "pg": self.getPageInfo(),
            "consent": self.getConsentInfo()
        ]
        
        if (!self.eventKey.isEmpty && !self.eventData.isEmpty) {
            jsonData[eventKey] = eventData
        }
        
        return self.dataToJson(jsonData)
    }
    
    // MARK: - Private functions
    
    fileprivate func getConsentInfo() -> Any {
        guard let consent = self.consent else {
            return NSNull();
        }
         
        return consent;
    }
    
    fileprivate func getPageInfo() -> [String: Any] {
        let pvInfoData: [String: Any] = [
            "vid": self.viewId,
        ]
        return pvInfoData;
    }
    
    fileprivate func getHitsInfo() -> [String: Any] {
        // Forms data and generate response
        var hitObj: [String: Any] = data
        hitObj["tp"] = self.type == "action" ? self.subType : self.getTypeIdentifier()
        hitObj["ht"] = self.dateToTimeStamp(Date())
        
        if (!self.hitsData.isEmpty) {
            var dataObj = [String: Any]()
            for (key, value) in hitsData {
                dataObj[key] = value
            }
            hitObj["data"] = dataObj;
        }
        return hitObj
    }
    
    fileprivate func getSystemInfo() -> [String: Any] {
	   // System info
        var namespace = "default"
        var accountId = "development"
        var siteId = ""
        if let info = self.info {
            if !info.namespaces.isEmpty {
                namespace = info.namespaces.joined(separator: ",")
            }
        
            accountId = info.accountId
            siteId = info.siteId ?? ""
        }

        let systemInfoData: [String: Any] = [
            "st": self.dateToTimeStamp(Date()),
            "tv": "6.0.0",
            "cs": 0,
            "is": hasValidGeoLocation() ? 0 : 1,
            "aid": accountId,
            "sid": siteId,
            "ns": namespace,
            "tt": "ios-post"
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
            "tz": (TimeZone.current.secondsFromGMT() / 60),
            "lang": lang,
            "conn": NetworkManager().getConnectionMode(),
            "sw":  UIScreen.main.bounds.width,
            "sh": UIScreen.main.bounds.height,
            "mem": "\(self.totalDiskSpaceInBytes())"
        ]
        
        if hasValidGeoLocation() {
            let locationData = [
                "geo": [
                    "latitude" : self.latitude,
                    "longitude": self.longitude
                ]
            ]
            return deviceInfoData.merging(locationData) { (current, _) in current }
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
        return self.isLocationEnabled && self.latitude != 0.0 && self.longitude != 0.0
    }
    
    fileprivate func getTypeIdentifier() -> String {
	   // Get the type of the hits 
        if self.type == "screenview" {
            return "sv"
        } else if self.type == "pageview" {
            return "pg"
        } else if self.type == "action" {
            return "ac"
        } else if self.type == "ids" {
            return "id"
        } else if self.type == "event" {
            return "ev"
        } else if self.type == "exception" {
            return "ex"
        } else if self.type == "social" {
            return "sc"
        } else if self.type == "timing" {
            return "ti"
        }
        
        return "ev"
    }
    
    fileprivate func getDefaultEventsFromType(_ type: String) -> [String] {
	   // Get the default data type ids of the hits
        if type == "screenview" {
            return ["id", "name"]
        } else if type == "action" {
            return ["id", "title", "viewId", "url", "referrer"]
        } else if type == "action" {
            return ["id", "tax", "discount", "currencyCode", "revenue"]
        } else if type == "ids" {
            return ["key", "value", "label"]
        } else if type == "event" || type == "exception" || type == "social" || type == "timing" {
            return ["category", "action", "label", "value"]
        }
        
        return [""]
    }
    
    fileprivate func getIDFA() -> String? {
        // Check whether advertising tracking is enabled
        if #available(iOS 14, *) {
            if ATTrackingManager.trackingAuthorizationStatus != ATTrackingManager.AuthorizationStatus.authorized  {
                return nil
            }
        } else {
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled == false {
                return nil
            }
        }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
}
