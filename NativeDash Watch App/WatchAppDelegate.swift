//
//  WatchAppDelegate.swift
//  NativeDash Watch App
//
//  Created by Dalton Harrold on 7/10/24.
//

import Foundation
import WatchKit
import OSLog

class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationWillEnterForeground() {
        // Schedule background application data refresh
        let preferredDate = Date().addingTimeInterval(24 * 60 * 60)// One day later
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: preferredDate, userInfo: "com.icloud-djharrold53.NativeDash.watchkitapp.DayTypeUpdater" as NSSecureCoding & NSObjectProtocol) { (error) in guard error == nil else {
            Logger.background.error("Couldn't schedule background refresh.")
            return
        }
            // Manually triger task execution:
            // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.icloud-djharrold53.NativeDash.watchkitapp.DayTypeUpdater"]
            
            // Manually cancel a task during execution
            // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.icloud-djharrold53.NativeDash.watchkitapp.DayTypeUpdater"]
            Logger.background.info("Scheduled next background update task for: \(preferredDate)")
        }
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        Logger.background.info("Starting WK background fetch")
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.icloud-djharrold53.NativeDash.watchkitapp.BGURLSession")
        configuration.isDiscretionary = true
        configuration.sessionSendsLaunchEvents = true
        
        let bgFetchUtil = BackgroundFetchUtil(withSessionConfig: configuration)
        bgFetchUtil.afterEveryFetch = {
            for task in backgroundTasks {
                let preferredDate = Date().addingTimeInterval(24 * 60 * 60)// One day later
                WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: preferredDate, userInfo: "com.icloud-djharrold53.NativeDash.watchkitapp.DayTypeUpdater" as NSSecureCoding & NSObjectProtocol) { (error) in guard error == nil else {
                    Logger.background.error("Couldn't schedule background refresh. \(error)")
                    return
                }
                }
                task.setTaskCompletedWithSnapshot(true)
            }
        }
        
        
        for task in backgroundTasks {
            task.expirationHandler = {bgFetchUtil.cancel()}
        }
        
        bgFetchUtil.start()
    
    }

}
