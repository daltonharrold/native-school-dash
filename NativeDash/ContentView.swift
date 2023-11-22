//
//  ContentView.swift
//  NativeDash
//
//  Created by student on 9/13/23.
//

import SwiftUI



struct ContentView: View {
    @Binding var todaySchedule: DayType

    @State var schedules: [DayType]
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [])
    private var scheduleStore: FetchedResults<StoredDayType>

    
    var body: some View {
            ScrollView(.vertical, showsIndicators: false) {
                    Spacer().frame(height: 50)
                    PeriodTimerRing(todaySchedule: $todaySchedule)
                    ScheduleStack(schedules: $schedules)
                    .padding(.horizontal, 40)
            }
        // Load schedules from local stores while app launches
        .task {
            for schedule in scheduleStore {
                schedules.append(DayType(name: schedule.wrappedName, periods: schedule.periodsArray))
            }
        }
        // Fetch schedule data from API to stay up to date
        .task {
            do {
                let fetchedSchedules = try await getFromApi()
                
                // Set UI State to new schedules
                schedules = fetchedSchedules!.dayTypes
                
                // Delete previous local stores
                scheduleStore.forEach(viewContext.delete)
                
                // Store new schedules that have been fetched
                for schedule in fetchedSchedules!.dayTypes {
                    _ = schedule.toStoredDayType(context: viewContext)
                    
                }
            
                // Set today's schedule to the fetched schedule
                todaySchedule = fetchedSchedules!.dayTypeOnDate
            } catch {
                schedules = [DayType(name: "Fetch Error", periods: [])]
            }
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
        ContentView(todaySchedule: .constant(todaySchedule), schedules: schedules)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
