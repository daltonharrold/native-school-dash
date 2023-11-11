//
//  ContentView.swift
//  NativeDash
//
//  Created by student on 9/13/23.
//

import SwiftUI



struct ContentView: View {
    @Binding var todaySchedule: DayType
    @Binding var schedules: [DayType]
    
    var body: some View {
            ScrollView(.vertical, showsIndicators: false) {
                    Spacer().frame(height: 50)
                    PeriodTimerRing(todaySchedule: $todaySchedule)
                    ScheduleStack(schedules: $schedules)
                    .padding(.horizontal, 40)
            }
            
    }
}

struct ContentView_Previews: PreviewProvider {
    static var schedules: [DayType] = [
        DayType(
            name: "Regular Schedule",
            periods: [
                .init(name: "Assembly", start: "8:30", end: "8:45"),
                .init(name: "Period 1", start: "8:49", end: "9:32"),
                .init(name: "Period 2", start: "9:35", end: "10:17"),
                .init(name: "Period 3", start: "10:21", end: "11:03"),
            ]
        ),
        DayType(
            name: "Different Schedule",
            periods: [
                .init(name: "Assembly", start: "8:38", end: "8:23"),
                .init(name: "Period 1", start: "8:04", end: "9:54"),
                .init(name: "Period 2", start: "9:23", end: "10:49"),
                .init(name: "Period 3", start: "10:52", end: "11:42"),
            ]
        )
    ]
    static var todaySchedule =  DayType(
        name: "Regular Schedule",
        periods: [
            .init(name: "Assembly", start: "8:30", end: "8:45"),
            .init(name: "Period 1", start: "8:49", end: "9:32"),
            .init(name: "Period 2", start: "9:35", end: "10:17"),
            .init(name: "Period 3", start: "10:21", end: "11:03"),
        ]
    )
    static var previews: some View {
        ContentView(todaySchedule: .constant(todaySchedule), schedules: .constant(schedules))
    }
}
