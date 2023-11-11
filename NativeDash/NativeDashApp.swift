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
    
    var body: some Scene {
        WindowGroup {
            ContentView(todaySchedule: $todaySchedule, schedules: $schedules)
                // Fetch schedule data
                .task {
                    do {
                        let fetchedSchedules = try await testDecode()
                        schedules = fetchedSchedules!.dayTypes
                        todaySchedule = fetchedSchedules!.dayTypeOnDate
                    } catch {
                        schedules = [DayType(name: "Fetch Error", periods: [])]
                    }
                }
        
        }
    }
    

    
}


