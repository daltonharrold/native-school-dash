//
//  ContentView.swift
//  NativeDash
//
//  Created by student on 9/13/23.
//

import SwiftUI



struct ContentView: View {
    
    @Environment(\.managedObjectContext) public var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    private var todayScheduleStore: FetchedResults<StoredDayType>


    @FetchRequest(sortDescriptors: [])
    private var weeklyScheduleStore: FetchedResults<StoredScheduleOnDate>
    
    @State private var todaySchedule: DayType?
    
    @State private var schedules: [DayType]?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Spacer().frame(height: 50)
            if todaySchedule != nil {
                PeriodTimerRing(todaySchedule: todaySchedule!)
            }
        
            if schedules != nil {
                ScheduleStack(schedules: schedules!)
                    .padding(.horizontal, 40)
            }
            
            Text("JBS Dash for iOS made with ❤️ by Dalton Harrold")
                .font(.footnote)
                .foregroundStyle(.gray)
                .padding(.top, 20)
        }
        // Before view loads, update schedules and todaySchedule
        .onAppear(perform: {
            let scheduleFromWeeklyStore = weeklyScheduleStore.first(where: {Calendar.current.isDateInToday($0.date!)})?.schedule?.asDayType()
            todaySchedule = scheduleFromWeeklyStore
            
            var tmpSchedules: [DayType] = []
            if !todayScheduleStore.isEmpty {
                for dayType in todayScheduleStore {
                    tmpSchedules.append(dayType.asDayType())
                }
                
                tmpSchedules.move(fromOffsets: [tmpSchedules.firstIndex(where: {$0.name == todaySchedule?.name}) ?? 0], toOffset: 0)
                schedules = tmpSchedules
            }
        })
        .task {
            await updateScheduleStores(viewContext: viewContext)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
//    static var schedules: [DayType] = [
//        DayType(
//            name: "Regular Schedule",
//            periods: [
//                .init(name: "Assembly", start: "8:30", end: "8:45"),
//                .init(name: "Period 1", start: "8:49", end: "9:32"),
//                .init(name: "Period 2", start: "9:35", end: "10:17"),
//                .init(name: "Period 3", start: "10:21", end: "11:03"),
//            ]
//        ),
//        DayType(
//            name: "Different Schedule",
//            periods: [
//                .init(name: "Assembly", start: "8:38", end: "8:23"),
//                .init(name: "Period 1", start: "8:04", end: "9:54"),
//                .init(name: "Period 2", start: "9:23", end: "10:49"),
//                .init(name: "Period 3", start: "10:52", end: "11:42"),
//            ]
//        )
//    ]
//    static var todaySchedule =  DayType(
//        name: "Regular Schedule",
//        periods: [
//            .init(name: "Assembly", start: "8:30", end: "8:45"),
//            .init(name: "Period 1", start: "8:49", end: "9:32"),
//            .init(name: "Period 2", start: "9:35", end: "10:17"),
//            .init(name: "Period 3", start: "10:21", end: "11:03"),
//        ]
//    )
    
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
