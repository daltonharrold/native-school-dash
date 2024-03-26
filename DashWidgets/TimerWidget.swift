//
//  TimerWidget.swift
//  DashWidgets
//
//  Created by Dalton Harrold on 2/8/24.
//

import WidgetKit
import SwiftUI

struct TimerProvider: TimelineProvider {
    
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
    
    func placeholder(in context: Context) -> TimerEntry {
        return TimerEntry(date: .now, displayPeriod: placeholderSixthPeriod, scheduleName: "Regular Day")
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> ()) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }

        let entry = TimerEntry(date: .now, displayPeriod: placeholderSixthPeriod, scheduleName: "Regular Day")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [TimerEntry] = []
        
        let viewContext = PersistenceController.shared.container.viewContext
        let scheduleFetch = StoredScheduleOnDate.fetchRequest()
        
        // TODO: Make it so that end of day and start of day show static start time for school tomorrow.
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
                    
                    let entry = TimerEntry(date: periodStart, displayPeriod: loopedPeriod, scheduleName: todaySchedule.name)
                    entries.append(entry)
                    
                    // Add passing period after current loop period except last period
                    if index < todaySchedule.periods.count - 1 {
                        let passingPeriod: Period = Period(name: "\(loopedPeriod.name) → \(todaySchedule.periods[index+1].name)", start: loopedPeriod.end, end: todaySchedule.periods[index+1].start)
                        
                        let passingStart = passingPeriod.getStartAsDate()
                        
                        let passingEntry = TimerEntry(date: passingStart, displayPeriod: passingPeriod, scheduleName: todaySchedule.name)
                        entries.append(passingEntry)
                    }
                }
            }
        } catch {
            fatalError("Could not fetch from Core Data for widget timeline. \(error)")
        }
        

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct TimerEntry: TimelineEntry {
    let date: Date
    let displayPeriod: Period
    let scheduleName: String
}

struct DashWidgetsEntryView : View {
    var entry: TimerProvider.Entry
    

    var body: some View {
        VStack{
            // Day type name
                Text(entry.scheduleName)
                    .font(.footnote)
                //                .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(entry.scheduleName)
                    .transition(.push(from: .top))
//                .background(.blue)
                
                
            // Timer

                Text(entry.displayPeriod.getEndAsDate(), style: .timer)
                    .font(.system(size: 52, weight: .bold))
                    .fontWidth(.compressed)
                //                .frame(minHeight: 0)
                    .padding(0)
                    .dynamicTypeSize(.medium)
                    .minimumScaleFactor(0.8)
                    .id(entry.displayPeriod.getEndAsDate())
                //                .transition(.push(from: .leading))
                    .transition(.move(edge: .leading))
        
//                .background(.red)
            
            Spacer()
            
            // Period information
                Text("\(entry.displayPeriod.name)\n\(entry.displayPeriod.twelveHrStart)-\(entry.displayPeriod.twelveHrEnd)")
                    .lineLimit(2, reservesSpace: true)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(entry.displayPeriod.name)
                    .transition(.push(from: .bottom))
//                .background(.green)
    
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//        .background(.orange)
    }
}

struct TimerWidget: Widget {
    let kind: String = "TimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerProvider()) { entry in
    
            DashWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)

        }
        .configurationDisplayName("Time Left in Period")
        .description("A widget to display how much time is left in the current period at a glance.")
//        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    TimerWidget()
} timeline: {
    TimerEntry(date: Calendar.current.date(bySettingHour: 12, minute: 55, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6", start: "12:39", end: "13:21"), scheduleName: "Regular Day")
    TimerEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6 → Period 7", start: "13:21", end: "13:25"), scheduleName: "Regular Day")
    TimerEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 7", start: "13:25", end: "14:07"), scheduleName: "Regular Day")
    TimerEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 8", start: "13:25", end: "14:07"), scheduleName: "Common Day")
}
