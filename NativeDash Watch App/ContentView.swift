//
//  ContentView.swift
//  NativeDash Watch App
//
//  Created by student on 9/13/23.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    
    @State private var todaySchedule: DayType?
    
    @State private var degree:Int = 270
    @State private var spinnerLength = 0.6
    
    private var fetchUtil = FetchUtil(context: PersistenceController.shared.backgroundContext)
    
    var body: some View {
        // If there's schedules in the stores, display the period timer ring
        if todaySchedule != nil {
            PeriodTimerRing(todaySchedule: todaySchedule!)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        
        Spacer()
            .frame(width: 0, height: 0)
            .onAppear(perform: {
                updateFromStores()
            })
            .onReceive(NotificationCenter.default.publisher(for: WKApplication.willEnterForegroundNotification), perform: { _ in
                updateFromStores()
            })
            .task {
                // If there's no schedules for the day detected in stores,
                // then run at a higher priority
                if todaySchedule == nil {
                    fetchUtil.context = PersistenceController.shared.viewContext
                }
                fetchUtil.completion = {_ in
                    updateFromStores()
                    WidgetCenter.shared.reloadAllTimelines()
                }
                fetchUtil.updater.start()
            }
    }
    
    
    private func updateFromStores() {
        let viewContext = PersistenceController.shared.viewContext
        let weeklyScheduleStore = try? viewContext.fetch(StoredScheduleOnDate.fetchRequest())
        
        let scheduleFromWeeklyStore = weeklyScheduleStore?.first(where: {Calendar.current.isDateInToday($0.date!)})?.schedule?.asDayType()
        todaySchedule = scheduleFromWeeklyStore
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
