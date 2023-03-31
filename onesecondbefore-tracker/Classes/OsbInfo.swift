//
//  OsbInfo.swift
//
//  Copyright (c) 2023 Onesecondbefore B.V. All rights reserved.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.  

class OSBInfo {
    var accountId: String = ""
    var serverUrl: String = ""
    var siteId: String?
    var domain: String?
    var debugMode: Bool = false
    var namespaces = [String]()
}
