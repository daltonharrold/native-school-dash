//
//  ContentView.swift
//  NativeDash Watch App
//
//  Created by student on 9/13/23.
//

import SwiftUI
import WatchKit
import Foundation

struct ContentView: View {
    
    @State private var schedules: [DayType]?
    @State private var todaySchedule: DayType?
    
    
    
    var body: some View {
        Text("Hello")
        if todaySchedule != nil {
            PeriodTimerRing(todaySchedule: todaySchedule!)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        EmptyView()
            .onAppear(perform: {
                print("App loading!")
                updateFromStores()
            })
            .onReceive(NotificationCenter.default.publisher(for: WKApplication.didBecomeActiveNotification)) {_ in
                print("App entering foreground!")
                updateFromStores()
            }
    }
    
    private func updateFromStores() {
        let viewContext = PersistenceController.shared.viewContext
        let weeklyScheduleStore = try? viewContext.fetch(StoredScheduleOnDate.fetchRequest())
        let dayTypesReq = StoredDayType.fetchRequest()
        dayTypesReq.sortDescriptors?.append(NSSortDescriptor(key: "name", ascending: true))
        let todayScheduleStore = try? viewContext.fetch(dayTypesReq)
        
        let scheduleFromWeeklyStore = weeklyScheduleStore?.first(where: {Calendar.current.isDateInToday($0.date!)})?.schedule?.asDayType()
        print("Setting todaySchedule to \(String(describing: scheduleFromWeeklyStore))")
        todaySchedule = scheduleFromWeeklyStore
        
        var tmpSchedules: [DayType] = []
        if !(todayScheduleStore?.isEmpty ?? true) {
            for dayType in todayScheduleStore! {
                tmpSchedules.append(dayType.asDayType())
            }
            
            tmpSchedules.move(fromOffsets: [tmpSchedules.firstIndex(where: {$0.name == todaySchedule?.name}) ?? 0], toOffset: 0)
            schedules = tmpSchedules
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
