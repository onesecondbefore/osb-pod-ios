//
//  NetworkManager.swift
//  OSB
//
//  Created by Crypton on 08/06/19.
//  Copyright (c) 2023 Onesecondbefore B.V. All rights reserved.
//

import Foundation
import SystemConfiguration

protocol NetworkManagerDelegate: AnyObject {
    func didNetworkConnected(_ isOnline: Bool)
}

class NetworkManager {

    var reachability: Reachability?
    weak var timer: Timer?

    weak var networkDelegate: NetworkManagerDelegate!

    func initialize() {
        setNotificationForInternet()
        startTimer()
    }

    // MARK: - Public functions

    public func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        if flags.isEmpty {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return (isReachable && !needsConnection)
    }

    public func getConnectionMode() -> String {
        // Gets the current device connection mode
        reachability = Reachability()

        if reachability?.connection != Reachability.Connection.none {
            if reachability?.connection == .wifi {
                return "wifi"
            } else if reachability?.connection == .cellular {
                return "cellular"
            }
        }

        return "offline"
    }

    // MARK: - Private functions

    fileprivate func setNotificationForInternet() {
        // Observing the reachability changes
        reachability = Reachability()
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: Notification.Name.reachabilityChanged, object: reachability)
        do {
            try reachability?.startNotifier()
        } catch {
            print("This is not working.")
            return
        }
    }

    @objc func reachabilityChanged(_ note: NSNotification) {
        reachability = note.object as? Reachability
        if let networkConnection = reachability?.connection.description {
            if networkConnection == "No Connection" {
                networkDelegate?.didNetworkConnected(false)
            } else {
                networkDelegate?.didNetworkConnected(true)
            }
        }
    }

    fileprivate func startTimer() {
        stopTimer()
        if #available(iOS 10.0, *) {
            // Checks the network status
            timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                self.setNotificationForInternet()
            }
        } else {
            // Fallback on earlier versions
        }
    }

    fileprivate func stopTimer() {
        timer?.invalidate()
    }
}
