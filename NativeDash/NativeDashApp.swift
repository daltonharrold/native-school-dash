//
//  NativeDashApp.swift
//  NativeDash
//
//  Created by student on 9/13/23.
//

import SwiftUI

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
    

    
}


