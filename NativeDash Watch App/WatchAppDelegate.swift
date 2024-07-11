//
//  WatchAppDelegate.swift
//  NativeDash Watch App
//
//  Created by Dalton Harrold on 7/10/24.
//

import Foundation
import WatchKit


class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationWillEnterForeground() {
        // Schedule background application data refresh
        let preferredDate = Date().addingTimeInterval(24 * 60 * 60)// One day later
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: preferredDate, userInfo: "com.icloud-djharrold53.NativeDash.watchkitapp.DayTypeUpdater" as NSSecureCoding & NSObjectProtocol) { (error) in guard error == nil else {
            print("Couldn't schedule background refresh.")
            return
        }
            // Manually triger task execution:
            // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.icloud-djharrold53.NativeDash.watchkitapp.DayTypeUpdater"]
            
            // Manually cancel a task during execution
            // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.icloud-djharrold53.NativeDash.watchkitapp.DayTypeUpdater"]
            print("Scheduled next background update task for: \(preferredDate)")
        }
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        print("Starting WK background fetch")
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.icloud-djharrold53.NativeDash.watchkitapp.BGURLSession")
        configuration.isDiscretionary = true
        configuration.sessionSendsLaunchEvents = true
        let bgFetchUtil = BackgroundFetchUtil()
        let session = URLSession(configuration: configuration, delegate: bgFetchUtil, delegateQueue: nil)
        
        for task in backgroundTasks {
            task.expirationHandler = {bgFetchUtil.cancel()}
        }
        
        var _dates: [Date] = []
        for i in 0...6 {_dates.append(Calendar.current.date(byAdding: .day, value: i, to: .now)!)}
        let dates = _dates
        
        for date in dates {
            let url = try! FetchUtil.getEndpointUrl(onDate: date)
            var req = URLRequest(url: url)
            let apiKey: String = try! FetchUtil.getApiKey()
            req.setValue(apiKey, forHTTPHeaderField: "authorization")
            
            let downloadTask = session.downloadTask(with: req)
            downloadTask.resume()
        }
    
    }

}
