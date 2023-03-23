//
//  UserAgent.swift
//
//  Copyright (c) 2023 Onesecondbefore B.V. All rights reserved.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.  

import Foundation
import UIKit

class UserAgent {
    // eg. Darwin/16.3.0
    fileprivate func DarwinVersion() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let dv = String(bytes: Data(bytes: &sysinfo.release, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
        return "Darwin/\(dv)"
    }

    // eg. CFNetwork/808.3
    fileprivate func CFNetworkVersion() -> String {
        let dictionary = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary!
        let version = dictionary?["CFBundleShortVersionString"] as! String
        return "CFNetwork/\(version)"
    }

    // eg. iOS/10_1
    fileprivate func deviceVersion() -> String {
        let currentDevice = UIDevice.current
        return "\(currentDevice.systemName)_\(currentDevice.systemVersion)"
    }

    // eg. iPhone5,2
    fileprivate func deviceName() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }

    // eg. OSBApp
    fileprivate func appName() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let name = dictionary["CFBundleName"] as! String
        return "\(name)"
    }

    // eg. 1.3.4
    fileprivate func appVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        return "\(version)"
    }

    public func UAString() -> String {
        return "\(appName())/\(appVersion()) (\(deviceName()); CPU OS \(deviceVersion()) like Mac OS X)"
    }
}
