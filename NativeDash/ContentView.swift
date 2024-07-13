//
//  ContentView.swift
//  NativeDash
//
//  Created by student on 9/13/23.
//

import SwiftUI
import WidgetKit
import OSLog


struct ContentView: View {
    
    @State private var todaySchedule: DayType?
    
    @State private var schedules: [DayType]?
    
    //DEBUGGING ONLY
    @State private var storesLastUpdated: String = UserDefaults.standard.string(forKey: "STORES_LAST_UPDATED") ?? "never"
    private func storesUpdated() {
        Thread.sleep(forTimeInterval: 20)
        widgetsLastUpdated = UserDefaults.standard.string(forKey: "STORES_LAST_UPDATED") ?? "Never"
    }
    @State private var widgetsLastUpdated: String = UserDefaults.standard.string(forKey: "WIDGETS_LAST_UPDATED") ?? "never"
    private func widgetsUpdated() {
        Thread.sleep(forTimeInterval: 0.1)
        widgetsLastUpdated = UserDefaults.standard.string(forKey: "WIDGETS_LAST_UPDATED") ?? "Never"
    }
    
    @State private var showSpinner:Bool = false
    @State private var degree:Int = 270
    @State private var spinnerLength = 0.6
    
    static var runningFetchUtil: FetchUtil?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Spacer().frame(height: 20)
            if todaySchedule != nil {
                PeriodTimerRing(todaySchedule: todaySchedule!)
            }
        
            if schedules != nil {
                ScheduleStack(schedules: schedules!)
                    .padding(.horizontal, 40)
            } else {
                VStack{
                    Circle()
                        .trim(from: 0.0,to: spinnerLength)
                        .stroke(Color("AccentColor"),style: StrokeStyle(lineWidth: 8.0,lineCap: .round,lineJoin:.round))
                        .animation(Animation.easeIn(duration: 1.5).repeatForever(autoreverses: true), value: degree)
                        .frame(width: 60,height: 60)
                        .rotationEffect(Angle(degrees: Double(degree)))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: spinnerLength)
                        .onAppear{
                            degree = 270 + 360
                            spinnerLength = 0
                        }
                    Text("Loading...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .fontWeight(.bold)
                        .font(.largeTitle)
                }
                
            }
            
            Text("JBS Dash for iOS made with ❤️ by Dalton Harrold")
                .font(.footnote)
                .foregroundStyle(.gray)
                .padding(.top, 20)
            
            // MARK: DEBUGGING ONLY
            HStack {
                Button(action: {
                    Logger.widget.debug("Widget refresh manually requested")
                    WidgetCenter.shared.reloadAllTimelines()
                    widgetsUpdated()
                }, label: {
                    Text("Reload Widgets")
                })
                Button(action: {
                    ContentView.runningFetchUtil = FetchUtil(context: PersistenceController.shared.backgroundContext)
                    ContentView.runningFetchUtil!.completion = {_ in
                        ContentView.runningFetchUtil = nil
                        updateFromStores()
                    }
                    ContentView.runningFetchUtil!.updater.start()
                    storesUpdated()
                }, label: {
                    Text("Re-fetch Core Data")
                })
            }
            Text("Last Core data fetch: \(storesLastUpdated)")
            Text("Last widget update: \(widgetsLastUpdated)")
            Spacer()
                .frame(height: 100)
            Text("Current Core Data:")
            Text("TodaySchedule: " + String(describing: todaySchedule))
            Spacer()
                .frame(height: 100)
            Text("schedules: " + String(describing: schedules))
        }
        

        Spacer()
        .onAppear(perform: {
            Logger.other.info("App loading!")
            updateFromStores()
        })
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: {_ in
            Logger.other.info("App entering foreground")
            updateFromStores()
        })
//        .task {
//            ContentView.runningFetchUtil = FetchUtil(context: PersistenceController.shared.backgroundContext)
//            ContentView.runningFetchUtil!.completion = {_ in
//                ContentView.runningFetchUtil = nil
//                updateFromStores()
//            }
//            ContentView.runningFetchUtil!.updater.start()
//            WidgetCenter.shared.reloadAllTimelines()
//        }
    }
    private func updateFromStores() {
        let viewContext = PersistenceController.shared.viewContext
        let weeklyScheduleStore = try? viewContext.fetch(StoredScheduleOnDate.fetchRequest())
        let dayTypesReq = StoredDayType.fetchRequest()
        dayTypesReq.sortDescriptors?.append(NSSortDescriptor(key: "name", ascending: true))
        let todayScheduleStore = try? viewContext.fetch(dayTypesReq)
        
        let scheduleFromWeeklyStore = weeklyScheduleStore?.first(where: {Calendar.current.isDateInToday($0.date!)})?.schedule?.asDayType()
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
    static var todaySchedule = DayType(
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
        ScrollView(.vertical){
            PeriodTimerRing(todaySchedule: todaySchedule)
            ScheduleStack(schedules: schedules)
                .padding(.horizontal, 40)
        }.scrollIndicators(.hidden)
    }
}
