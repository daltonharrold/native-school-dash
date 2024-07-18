//
//  AppDelegate.swift
//  NativeDash
//
//  Created by Dalton Harrold on 3/30/24.
//

import Foundation
import UIKit
import BackgroundTasks
import OSLog

class AppDelegate: UIResponder, UIApplicationDelegate {
    let appRefreshTaskId: String = "com.icloud-djharrold53.NativeDash.DayTypeUpdater"
    let viewContext = PersistenceController.shared.container.viewContext
    var sessionSendsLaunchEvents = true
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Register background task with system
        BGTaskScheduler.shared.register(forTaskWithIdentifier: appRefreshTaskId, using: nil, launchHandler: {task in
            // Handle task when run
            guard let task = task as? BGProcessingTask else {return}
            self.handleTask(task: task)
        })
        
        let count = UserDefaults.standard.integer(forKey: "BG_task_run_count")
        Logger.background.info("[NativeDash BG Scheduler]: task has run \(count) times")
       
        scheduleTask()
        
        return true
    }
    
    func handleTask(task: BGProcessingTask) {
        let count = UserDefaults.standard.integer(forKey: "BG_task_run_count")
        UserDefaults.standard.setValue(count+1, forKey: "BG_task_run_count")
        Logger.background.info("[NativeDash BG Scheduler]: Running scheduled task...")
        
        let config = URLSessionConfiguration.background(withIdentifier: "com.icloud-djharrold53.NativeDash.BGURLSession")
        config.sessionSendsLaunchEvents = true
        let bgFetchUtil = BackgroundFetchUtil()
        bgFetchUtil.completionBlock = {
            self.scheduleTask()
            if bgFetchUtil.error == nil {
                task.setTaskCompleted(success: true)
            } else {
                task.setTaskCompleted(success: false)
            }
        }
        let session = URLSession(configuration: config, delegate: bgFetchUtil, delegateQueue: OperationQueue())
        task.expirationHandler = {bgFetchUtil.cancel()}
        
        
        
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
    
    
    
    func scheduleTask() {
        // Manually triger task execution:
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.icloud-djharrold53.NativeDash.DayTypeUpdater"]
        
        // Manually cancel a task during execution
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.icloud-djharrold53.NativeDash.DayTypeUpdater"]
        
        BGTaskScheduler.shared.getPendingTaskRequests { requests in
            guard requests.isEmpty else {return}
            //Submit a task to be scheduled
            do {
                let newTask = BGProcessingTaskRequest(identifier: self.appRefreshTaskId)
                newTask.earliestBeginDate = Calendar.current.date(byAdding: .day, value: 1, to: .now)
                newTask.requiresNetworkConnectivity = true
                
                try BGTaskScheduler.shared.submit(newTask)
                Logger.background.info("[NativeDash BG Scheduler]: new task successfully scheduled")
            } catch {
                Logger.other.error("Task failed to schedule. \(error)")
            }
        }
        
    }
    


}

