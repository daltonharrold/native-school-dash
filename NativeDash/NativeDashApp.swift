//
//  NativeDashApp.swift
//  NativeDash
//
//  Created by student on 9/13/23.
//

import SwiftUI
import BackgroundTasks

@main
struct NativeDashApp: App {
    @State var todaySchedule: DayType = DayType(name: "Fetch Awaiting...", periods: [])
    @State var schedules: [DayType] = []
    
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            ContentView(todaySchedule: $todaySchedule, schedules: schedules)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        
        }
    }
    init() {
        self.todaySchedule = DayType(name: "Fetch Awaiting...", periods: [])
        self.schedules = []
        /*
        // Register background task with the system
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.icloud-djharrold53.NativeDash.DayTypeUpdater", using: nil) { task in
             self.handleDayTypeRefresh(task: task as! BGAppRefreshTask)
        }*/
    }
    /*
    // Refresh the DayTypes in the background daily
    func scheduleDayTypeRefresh() {
       let request = BGAppRefreshTaskRequest(identifier: "com.icloud-djharrold53.NativeDash.DayTypeUpdater")
       // Fetch no earlier than 24 hours from now.
       request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60 * 24)
        
            
       do {
          try BGTaskScheduler.shared.submit(request)
       } catch {
          print("Could not schedule app refresh: \(error)")
       }
    }
    
    
    func handleDayTypeRefresh(task: BGAppRefreshTask) {
       // Schedule a new refresh task.
       scheduleDayTypeRefresh()

       // Create an operation that performs the main part of the background task.
       let operation = RefreshAppContentsOperation()
       
       // Provide the background task with an expiration handler that cancels the operation.
       task.expirationHandler = {
          operation.cancel()
       }


       // Inform the system that the background task is complete
       // when the operation completes.
       operation.completionBlock = {
          task.setTaskCompleted(success: !operation.isCancelled)
       }


       // Start the operation.
       operationQueue.addOperation(operation)
     }
*/
    
}


