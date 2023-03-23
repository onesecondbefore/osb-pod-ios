//
//  ApiQueue.swift
//
//  Copyright (c) 2023 Onesecondbefore B.V. All rights reserved.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.  

import Foundation

private struct Queue<T> {
    fileprivate var array = [T]()

    public var count: Int {
        return array.count
    }

    public var isEmpty: Bool {
        return array.isEmpty
    }

    public mutating func enqueue(_ element: T) {
        array.append(element)
    }

    public mutating func dequeue() -> T? {
        if isEmpty {
            return nil
        } else {
            return array.removeFirst()
        }
    }

    public var front: T? {
        return array.first
    }
}

private struct QueueTask {
    var data: String = ""
    var url: String = ""
}

public class ApiQueue: NetworkManagerDelegate {
    fileprivate var queue: Queue = Queue<QueueTask>()
    fileprivate var networkManager = NetworkManager()
    fileprivate var isInitialized: Bool = false
    fileprivate let userAgent: String = UserAgent().UAString()

    func initialize() {
        isInitialized = true
        networkManager.initialize()
        networkManager.networkDelegate = self
        unserializeQueue()
        groupTasks()
    }

    func didNetworkConnected(_ isOnline: Bool) {
        if !isInitialized {
            initialize()
        }

        if isOnline {
            groupTasks()
            processQueue()
        }
    }

    func addToQueue(_ url: String, data: String) {
        if !isInitialized {
            initialize()
        }
        var task = QueueTask()
        task.data = data
        task.url = url
        queue.enqueue(task)
        processQueue()
    }

    func processQueue() {
        // Check the queue is ready and connected to network
        if !queue.isEmpty && networkManager.isConnectedToNetwork() {
            DispatchQueue.main.async {
                if let task = self.queue.dequeue() {
                    self.callApi(task)
                }
            }
        } else if !queue.isEmpty {
            DispatchQueue.main.async {
                self.serializeQueue()
            }
        }
    }

    // MARK: - Private functions

    fileprivate func callApi(_ task: QueueTask) {
        // Send the queue data to server endpoint
        let url = URL(string: task.url)!
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpMethod = "POST"
        request.httpBody = task.data.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let _ = data, error == nil else {
                self.processQueue()
                return
            }

            if error != nil {
                self.processQueue()
            }
        }

        task.resume()
    }

    fileprivate func serializeQueue() {
        var taskArray = [String]()
        var url = String()
        let defaults = UserDefaults.standard

        queue.array.forEach({ task in
            taskArray.append(task.data)
        })

        if queue.array.count != 0 {
            url = queue.array[0].url
        }

        defaults.setValue(taskArray, forKey: "osb-defaults-tasks")
        defaults.setValue(url, forKey: "osb-defaults-url")
    }

    fileprivate func unserializeQueue() {
        let defaults = UserDefaults.standard
        let taskData = defaults.value(forKey: "osb-defaults-tasks") as? [String] ?? []
        let taskUrl = defaults.value(forKey: "osb-defaults-url") as? String ?? ""

        if !taskData.isEmpty && !taskUrl.isEmpty {
            taskData.forEach({ data in
                var task = QueueTask()
                task.data = data
                task.url = taskUrl

                self.queue.enqueue(task)
            })
        }

        defaults.removeObject(forKey: "osb-defaults-url")
        defaults.removeObject(forKey: "osb-defaults-tasks")
    }

    fileprivate func groupTasks() {
        if queue.array.count > 1 {
            var task = QueueTask()
            var data = [String]()

            queue.array.forEach({ task in
                data.append(task.data)
            })

            task.data = getGroupedData(data)
            task.url = queue.array[0].url

            queue.array.removeAll()
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "osb-defaults-url")
            defaults.removeObject(forKey: "osb-defaults-tasks")
            queue.enqueue(task)
        }
    }

    fileprivate func getGroupedData(_ responseData: [String]) -> String {
        var hitsDict = [[String: Any]]()
        var sysInfo = [String: Any]()
        var deviceInfo = [String: Any]()

        // Forms new single data from array of json offline data
        for data in responseData {
            if let dataDict = convertToData(data) {
                let histObject = dataDict["hits"] as? [[String: Any]] ?? [[String: Any]]()
                sysInfo = dataDict["sy"] as? [String: Any] ?? [String: Any]()
                let serverTime = Int64(Date().timeIntervalSince1970 * 1000)
                sysInfo["sy"] = serverTime
                deviceInfo = dataDict["dv"] as? [String: Any] ?? [String: Any]()
                for hits in histObject {
                    hitsDict.append(hits)
                }
            }
        }

        let jsonData: [String: Any] = ["sy": sysInfo, "dv": deviceInfo, "hits": hitsDict]

        let data = try! JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        return jsonString
    }

    fileprivate func convertToData(_ responseData: String) -> [String: Any]? {
        // Convert Json response string to data dictionary
        if let data = responseData.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
