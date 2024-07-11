//
//  ContentView.swift
//  NativeDash Watch App
//
//  Created by student on 9/13/23.
//

import SwiftUI

struct ContentView: View {
    @FetchRequest(sortDescriptors: [])
    private var weeklyScheduleStore: FetchedResults<StoredScheduleOnDate>
    
    
    @State var todaySchedule: DayType? = DayType(
        name: "Common Day",
        periods: [
            .init(name: "Assembly", start: "8:30", end: "8:37"),
            .init(name: "Period 1", start: "8:41", end: "9:20"),
            .init(name: "Period 2", start: "9:24", end: "10:03"),
            .init(name: "Period 3", start: "10:07", end: "10:46"),
            .init(name: "Common", start: "10:50", end: "11:17"),
            .init(name: "Period 4", start: "11:21", end: "12:01"),
            .init(name: "Period 5", start: "12:05", end: "12:45"),
            .init(name: "Period 6", start: "12:49", end: "13:29"),
            .init(name: "Period 7", start: "13:33", end: "14:13"),
            .init(name: "Period 8", start: "14:17", end: "14:57"),
            .init(name: "Period 9", start: "15:01", end: "15:41"),
            .init(name: "Period 10", start: "15:45", end: "16:25")
        ]
    )
    
    var body: some View {
        if todaySchedule != nil {
            PeriodTimerRing(todaySchedule: todaySchedule!)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        EmptyView()
            .onAppear(perform: {
                let scheduleFromWeeklyStore = weeklyScheduleStore.first(where: {Calendar.current.isDateInToday($0.date!)})?.schedule?.asDayType()
                todaySchedule = todaySchedule ?? scheduleFromWeeklyStore
            })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var todaySchedule: DayType = DayType(
        name: "Common Day",
        periods: [
            .init(name: "Assembly", start: "8:30", end: "8:37"),
            .init(name: "Period 1", start: "8:41", end: "9:20"),
            .init(name: "Period 2", start: "9:24", end: "10:03"),
            .init(name: "Period 3", start: "10:07", end: "10:46"),
            .init(name: "Common", start: "10:50", end: "11:17"),
            .init(name: "Period 4", start: "11:21", end: "12:01"),
            .init(name: "Period 5", start: "12:05", end: "12:45"),
            .init(name: "Period 6", start: "12:49", end: "13:29"),
            .init(name: "Period 7", start: "13:33", end: "14:13"),
            .init(name: "Period 8", start: "14:17", end: "14:57"),
            .init(name: "Period 9", start: "15:01", end: "15:41"),
            .init(name: "Period 10", start: "15:45", end: "16:25")
        ]
    )
    static var previews: some View {
        ContentView()
    }
}
