//
//  TimerWatchWidget.swift
//  DashWatchWidgetsExtension
//
//  Created by Dalton Harrold on 4/8/24.
//

import WidgetKit
import SwiftUI

struct TimerWatchProvider: TimelineProvider {
    
    var currentHour: Int {
        Calendar.current.component(.hour, from: .now)
    }
    var currentMinute : Int {
        Calendar.current.component(.minute, from: .now)
    }
    var placeholderSixthPeriod: Period {
        var endMinute: Int = 0
        var endHour: Int = 0
        if currentMinute > 60-14 {
            endHour = currentHour + 1
            endMinute = (currentMinute + 14) % 60
        } else {
            endHour = currentHour
            endMinute = currentMinute + 14
        }
        return Period(name: "Period 6", start: "00:00", end: "\(endHour):\(endMinute)")
    }
    
    func placeholder(in context: Context) -> TimerWatchEntry {
        return TimerWatchEntry(date: .now, displayPeriod: placeholderSixthPeriod, scheduleName: "Regular Day")
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerWatchEntry) -> ()) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }

        let entry = TimerWatchEntry(date: .now, displayPeriod: placeholderSixthPeriod, scheduleName: "Regular Day")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [TimerWatchEntry] = []
        
        let viewContext = PersistenceController.shared.container.viewContext
        let scheduleFetch = StoredScheduleOnDate.fetchRequest()
        
       
        do {
            let storedSchedules = try viewContext.fetch(scheduleFetch)
            
            let currentDate = Date()
            if let todaySchedule = storedSchedules.first(where: {
                Calendar.current.isDate($0.date!, equalTo: currentDate, toGranularity: .day)
            })?.schedule?.asDayType() {
                for index in 0..<todaySchedule.periods.count {
                    let loopedPeriod = todaySchedule.periods[index]
                    
                    // Add the period to entries
                    let periodStart = loopedPeriod.getStartAsDate()
                    
                    let entry = TimerWatchEntry(date: periodStart, displayPeriod: loopedPeriod, scheduleName: todaySchedule.name)
                    entries.append(entry)
                    
                    // Add passing period after current loop period except last period
                    if index < todaySchedule.periods.count - 1 {
                        let passingPeriod: Period = Period(name: "\(loopedPeriod.name) → \(todaySchedule.periods[index+1].name)", start: loopedPeriod.end, end: todaySchedule.periods[index+1].start)
                        
                        let passingStart = passingPeriod.getStartAsDate()
                        
                        let passingEntry = TimerWatchEntry(date: passingStart, displayPeriod: passingPeriod, scheduleName: todaySchedule.name)
                        entries.append(passingEntry)
                    }
                }
                // Have an entry at the end of the day to have the start time of the next day shown
                if let tomorrowSchedule = storedSchedules.first(where: {
                    Calendar.current.isDate($0.date!, equalTo: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!, toGranularity: .day)
                })?.schedule?.asDayType() {
                    // At EOD, show tomorrow's start
                    let endOfDay: Date = todaySchedule.periods.last!.getEndAsDate()
                    let overnightPeriod: Period = Period(name: "Night time", start: todaySchedule.periods.last!.end, end: tomorrowSchedule.periods.first!.start)
                    let overnightEntry = TimerWatchEntry(date: endOfDay, displayPeriod: overnightPeriod, scheduleName: tomorrowSchedule.name, tomorrowSchoolStart: tomorrowSchedule.periods.first!.getStartAsDate())
                    
                    entries.append(overnightEntry)

                }
            }
        } catch {
            fatalError("Could not fetch from Core Data for widget timeline. \(error)")
        }
        

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct TimerWatchEntry: TimelineEntry {
    let date: Date
    let displayPeriod: Period
    let scheduleName: String
    let tomorrowSchoolStart: Date?
    
    init(date: Date, displayPeriod: Period, scheduleName: String, tomorrowSchoolStart: Date?) {
        self.date = date
        self.displayPeriod = displayPeriod
        self.scheduleName = scheduleName
        self.tomorrowSchoolStart = tomorrowSchoolStart
    }
    
    init(date: Date, displayPeriod: Period, scheduleName: String) {
        self.date = date
        self.displayPeriod = displayPeriod
        self.scheduleName = scheduleName
        self.tomorrowSchoolStart = nil
    }
}

struct TimerWatchWidgetEntryView : View {
    var entry: TimerWatchProvider.Entry

    var body: some View {
            VStack {
                if entry.tomorrowSchoolStart == nil {
                    Text(entry.displayPeriod.getEndAsDate(), style: .timer)
                        .font(.system(size: 42, weight: .bold))
                        .fontWidth(.compressed)
                        .minimumScaleFactor(0.9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(entry.tomorrowSchoolStart!, style: .time)
                        .font(.system(size: 42, weight: .bold))
                        .fontWidth(.compressed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                }
            }
            Text("\(entry.displayPeriod.name)")
                .lineLimit(1, reservesSpace: true)
                .font(.callout)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TimerWatchWidget: Widget {
    let kind: String = "TimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerWatchProvider()) { entry in
    
            TimerWatchWidgetEntryView(entry: entry)
                .containerBackground(LinearGradient(colors: [Color("AccentColor"), Color("EmptyAccentColor")], startPoint: .topLeading, endPoint: .bottomTrailing), for: .widget)

        }
        .configurationDisplayName("Time Left in Period")
        .description("A widget to display how much time is left in the current period at a glance.")
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview(as: .accessoryRectangular) {
    TimerWatchWidget()
} timeline: {
    TimerWatchEntry(date: Calendar.current.date(bySettingHour: 12, minute: 55, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6", start: "12:39", end: "13:21"), scheduleName: "Regular Day")
    TimerWatchEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6 → Period 7", start: "13:21", end: "13:25"), scheduleName: "Regular Day")
    TimerWatchEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 7", start: "13:25", end: "14:07"), scheduleName: "Regular Day")
    TimerWatchEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 8", start: "13:25", end: "14:07"), scheduleName: "Common Day")
}
