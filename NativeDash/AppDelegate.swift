//
//  AppDelegate.swift
//  NativeDash
//
//  Created by Dalton Harrold on 3/30/24.
//

import Foundation
import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    let appRefreshTaskId: String = "com.icloud-djharrold53.NativeDash.DayTypeUpdater"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Register background task with system
        BGTaskScheduler.shared.register(forTaskWithIdentifier: appRefreshTaskId, using: nil, launchHandler: {task in
            // Handle task when run
            guard let task = task as? BGProcessingTask else {return}
            self.handleTask(task: task)
        })
        
        let count = UserDefaults.standard.integer(forKey: "BG_task_run_count")
        print("[NativeDash BG Scheduler]: task has run \(count) times")
       
        scheduleTask()
        
        return true
    }
    
    func handleTask(task: BGProcessingTask) {
        let count = UserDefaults.standard.integer(forKey: "BG_task_run_count")
        UserDefaults.standard.setValue(count+1, forKey: "BG_task_run_count")
        print("[NativeDash BG Scheduler]: Running scheduled task...")
        
        
        
        
        task.expirationHandler = {
            
        }
        
        task.setTaskCompleted(success: true)
    }
    
    
    func scheduleTask() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        // Manually triger task execution:
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.icloud-djharrold53.NativeDash.DayTypeUpdater"]
        
        // Manually cancel a task during execution
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.icloud-djharrold53.NativeDash.DayTypeUpdater"]
        
        BGTaskScheduler.shared.getPendingTaskRequests { requests in
            print("[NativeDash BG Scheduler]: \(requests.count) tasks scheduled")
            guard requests.isEmpty else {return}
            //Submit a task to be scheduled
            do {
                let newTask = BGProcessingTaskRequest(identifier: self.appRefreshTaskId)
                newTask.earliestBeginDate = Calendar.current.date(byAdding: .day, value: 1, to: .now)
                newTask.requiresNetworkConnectivity = true
                
                try BGTaskScheduler.shared.submit(newTask)
                print("[NativeDash BG Scheduler]: new task successfully scheduled")
            } catch {
                print("Task failed to schedule. \(error)")
            }
        }
        
    }
    


}
