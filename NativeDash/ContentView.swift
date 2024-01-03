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
    private var todayScheduleStore: FetchedResults<StoredDayType>

    @FetchRequest(sortDescriptors: [])
    private var weeklyScheduleStore: FetchedResults<StoredScheduleOnDate>

    let calendar = Calendar(identifier: .iso8601)
    
    var body: some View {
            ScrollView(.vertical, showsIndicators: false) {
                    Spacer().frame(height: 50)
                PeriodTimerRing(todaySchedule: $todaySchedule)
                ScheduleStack(schedules: $schedules)
                    .padding(.horizontal, 40)
                
                Text("JBS Dash for iOS made with ❤️ by Dalton Harrold")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .padding(.top, 20)
            }
        
        // Load what the day type is today from stores while app launches
        .task {
            let scheduleFromWeeklyStore: [StoredScheduleOnDate] = weeklyScheduleStore.filter {Calendar.current.isDateInToday($0.date!)}
            todaySchedule = (scheduleFromWeeklyStore.count > 0) ? scheduleFromWeeklyStore[0].schedule!.asDayType() : todaySchedule
        }
        
        // Load schedules from local stores while app launches
        .task {
            for dayType in todayScheduleStore {
                schedules.append(DayType(name: dayType.wrappedName, periods: dayType.periodsArray))
            }
        }

        // Fetch schedule data from API to keep StoredDayType up to date
        
        .task {
            do {
                let fetchedSchedules = try await getDayTypeFromApi()
            
                // Set UI State to new schedules
                schedules = fetchedSchedules!.dayTypes
                
                // Delete previous local stores
                todayScheduleStore.forEach(viewContext.delete)
                
                // Store new schedules that have been fetched
                for schedule in fetchedSchedules!.dayTypes {
                    _ = schedule.toStoredDayType(context: viewContext)
                    
                }
            
                // Set today's schedule to the fetched schedule
                //todaySchedule = fetchedSchedules!.dayTypeOnDate
                
                try viewContext.save()
            } catch {
                schedules = [DayType(name: "Schedule Fetch Error", periods: [])]
            }
        }
        
        // Fetch schedule data from API to keep StoredScheduleOnDate up to date
        // This makes it so that we can assume what schedule it is on any day in widgets and on app load
        .task {
            do {
                var dates: [Date] = [Date.now]
                for i in (1...6) {
                    dates.append(Date.now.addingTimeInterval(TimeInterval(i*60*60*24)))
                }
                
                weeklyScheduleStore.forEach(viewContext.delete)
                
                
                for (index, date) in dates.enumerated() {
                    // Separate date object into components and get data from API
                    let components = calendar.dateComponents([.year, .month, .day], from: date)
                    let scheduleOnDate = try await getDayTypeFromApi(onDay: YearMonthDay(components: components))
                    
                    // Add the today date to the displayed schedule
                    if index == 0 {
                        todaySchedule = scheduleOnDate!.dayTypeOnDate
                    }
                    
                    // Save schedules in Core Data for quick future reference
                    let newSchedule = StoredScheduleOnDate(context: viewContext)
                    newSchedule.date = date
                    let possibleSchedule = todayScheduleStore.filter {$0.name == scheduleOnDate?.dayTypeOnDate.name}
                    newSchedule.schedule = possibleSchedule.count > 0 ? possibleSchedule[0] : todayScheduleStore[0]
                }
                try viewContext.save()
            } catch {
                schedules = [DayType(name: "Schedule Fetch Error", periods: [])]
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
