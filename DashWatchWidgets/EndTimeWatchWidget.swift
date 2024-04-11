//
//  EndTimeWatchWidget.swift
//  DashWatchWidgetsExtension
//
//  Created by Dalton Harrold on 4/8/24.
//

import Foundation
import WidgetKit
import SwiftUI

struct EndTimeWatchProvider: TimelineProvider {
    
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

    
    func placeholder(in context: Context) -> EndTimeWatchEntry {
        return EndTimeWatchEntry(date: .now, displayPeriod: placeholderSixthPeriod, scheduleName: "Regular Day")
    }

    func getSnapshot(in context: Context, completion: @escaping (EndTimeWatchEntry) -> ()) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }

        let entry = EndTimeWatchEntry(date: .now, displayPeriod: placeholderSixthPeriod, scheduleName: "Regular Day")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [EndTimeWatchEntry] = []
        
        let viewContext = PersistenceController.shared.container.viewContext
        let scheduleFetch = StoredScheduleOnDate.fetchRequest()
        
        do {
            let storedSchedules = try viewContext.fetch(scheduleFetch)
            
            let currentDate = Date()
            if let todaySchedule = storedSchedules.first(where: {
                Calendar.current.isDate($0.date!, equalTo: currentDate, toGranularity: .day)
            })?.schedule?.asDayType() {
                for index in 0..<todaySchedule.periods.count-1 {
                    let loopedPeriod = todaySchedule.periods[index]
                    
                    // Add the period to entries
                    
                    // Change at period end, so that passing periods will show as the end of next period
                    // Note: This means that the first period needs to be scheduled seperately below
                    let periodEnd = loopedPeriod.getEndAsDate()
                    
                    
                    let entry = EndTimeWatchEntry(date: periodEnd, displayPeriod: todaySchedule.periods[index+1], scheduleName: todaySchedule.name)
                    entries.append(entry)
                }
                
                
                // Have an entry at the end of the day to have the start time of the next day shown
                if let tomorrowSchedule = storedSchedules.first(where: {
                    Calendar.current.isDate($0.date!, equalTo: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!, toGranularity: .day)
                })?.schedule?.asDayType() {
                    // At EOD, show tomorrow's start
                    let endOfDay: Date = todaySchedule.periods.last!.getEndAsDate()
                    let overnightPeriod: Period = Period(name: "Night time", start: todaySchedule.periods.last!.end, end: tomorrowSchedule.periods.first!.start)
                    let overnightEntry = EndTimeWatchEntry(date: endOfDay, displayPeriod: overnightPeriod, scheduleName: tomorrowSchedule.name)
                    
                    entries.append(overnightEntry)
                    
                    // Schedule the first period of tomorrow
                    let tomorrowFirstPeriod: Period = tomorrowSchedule.periods.first!
                    let tomorrowFirstPeriodEntry: EndTimeWatchEntry = EndTimeWatchEntry(date: tomorrowFirstPeriod.getStartAsDate(), displayPeriod: tomorrowFirstPeriod, scheduleName: tomorrowSchedule.name)
                    
                    entries.append(tomorrowFirstPeriodEntry)
                }
            }
            
        } catch {
            fatalError("Could not fetch from Core Data for widget timeline. \(error)")
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct EndTimeWatchEntry: TimelineEntry {
    let date: Date
    let displayPeriod: Period
    let scheduleName: String
}

struct EndTimeWatchWidgetEntryView : View {
    var entry: EndTimeWatchProvider.Entry

    var body: some View {
       
        VStack{
            // Timer
            Text(entry.displayPeriod.getEndAsDate(), style: .time)
                .font(.system(size: 42, weight: .bold))
                .fontWidth(.compressed)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(entry.displayPeriod.name)")
                .lineLimit(1, reservesSpace: true)
                .font(.callout)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct EndTimeWatchWidget: Widget {
    let kind: String = "EndTimeWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EndTimeWatchProvider()) { entry in
            
                EndTimeWatchWidgetEntryView(entry: entry)
                .containerBackground(LinearGradient(colors: [Color("AccentColor"), Color("EmptyAccentColor")], startPoint: .topLeading, endPoint: .bottomTrailing), for: .widget)
          
        }
        .configurationDisplayName("Period End Time")
        .description("A widget to display at what time the current period ends, for when you want to use your own clock")
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview(as: .accessoryRectangular) {
    EndTimeWatchWidget()
} timeline: {
    EndTimeWatchEntry(date: Calendar.current.date(bySettingHour: 12, minute: 55, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6", start: "12:39", end: "13:21"), scheduleName: "Regular Day")
    EndTimeWatchEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6 → Period 7", start: "13:21", end: "13:25"), scheduleName: "Regular Day")
    EndTimeWatchEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 7", start: "13:25", end: "14:07"), scheduleName: "Regular Day")
    EndTimeWatchEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 8", start: "13:25", end: "14:07"), scheduleName: "Common Day")
}

