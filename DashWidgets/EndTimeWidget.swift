//
//  EndTimeWidget.swift
//  DashWidgetsExtension
//
//  Created by Dalton Harrold on 3/24/24.
//

import Foundation
import WidgetKit
import SwiftUI
import OSLog

struct EndTimeProvider: TimelineProvider {
    
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

    
    func placeholder(in context: Context) -> EndTimeEntry {
        return EndTimeEntry(date: .now, displayPeriod: placeholderSixthPeriod, scheduleName: "Regular Day")
    }

    func getSnapshot(in context: Context, completion: @escaping (EndTimeEntry) -> ()) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }

        let entry = EndTimeEntry(date: .now, displayPeriod: placeholderSixthPeriod, scheduleName: "Regular Day")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Logger.widget.info("Getting timeline for end time widget...")
        var entries: [EndTimeEntry] = []
        
        let context = PersistenceController.shared.backgroundContext
        let scheduleFetch = StoredScheduleOnDate.fetchRequest()
        
        do {
            let storedSchedules = try context.fetch(scheduleFetch)
            
            let currentDate = Date()
            if let todaySchedule = storedSchedules.first(where: {
                Calendar.current.isDate($0.date!, equalTo: currentDate, toGranularity: .day)
            })?.schedule?.asDayType() {
                
                // Have an entry at midnight when schedules are needed
                let morningStart = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: .now)!
                let morningPeriod = Period(name: "Good morning", start: "00:00", end: todaySchedule.periods.first!.start)
                let morningEntry = EndTimeEntry(date: morningStart, displayPeriod: morningPeriod, scheduleName: todaySchedule.name)
                entries.append(morningEntry)
                
                // Passing periods should show the next full period's end time.
                // This means that an entry's date should be the past period's end, or the start in the first period's case.
                
                let firstPeriod = todaySchedule.periods.first!
                let firstPeriodEntry = EndTimeEntry(date: firstPeriod.getStartAsDate(), displayPeriod: firstPeriod, scheduleName: todaySchedule.name)
                entries.append(firstPeriodEntry)
                
                for index in 1..<todaySchedule.periods.count {
                    let entry = EndTimeEntry(date: todaySchedule.periods[index-1].getEndAsDate(), displayPeriod: todaySchedule.periods[index], scheduleName: todaySchedule.name)
                    entries.append(entry)
                }
                
                
                // Have an entry at the end of the day to have the start time of the next day shown
                if let tomorrowSchedule = storedSchedules.first(where: {
                    Calendar.current.isDate($0.date!, equalTo: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!, toGranularity: .day)
                })?.schedule?.asDayType() {
                    // At EOD, show tomorrow's start
                    let endOfDay: Date = todaySchedule.periods.last!.getEndAsDate()
                    let overnightPeriod: Period = Period(name: "Good night", start: todaySchedule.periods.last!.end, end: "00:00")
                    let overnightEntry = EndTimeEntry(date: endOfDay, displayPeriod: overnightPeriod, scheduleName: tomorrowSchedule.name, overrideDisplayDate: tomorrowSchedule.periods.first!.getStartAsDate())
                    
                    entries.append(overnightEntry)
                }
            }
            
        } catch {
            Logger.widget.error("Could not fetch from Core Data for widget timeline. \(error)")
        }
        let tomorrowMorning = Calendar.current.date(bySettingHour: 0, minute: 1, second: 0, of: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)!
        let timeline = Timeline(entries: entries, policy: .after(tomorrowMorning))
        UserDefaults.standard.setValue(Date.now.ISO8601Format(), forKey: "WIDGETS_LAST_UPDATED")
        Logger.widget.info("Successfuly refreshed timeline for end time widget")
        completion(timeline)
    }
}

struct EndTimeEntry: TimelineEntry {
    let date: Date
    let displayPeriod: Period
    let scheduleName: String
    let overrideDisplayDate: Date?
    init(date: Date, displayPeriod: Period, scheduleName: String, overrideDisplayDate: Date) {
        self.date = date
        self.displayPeriod = displayPeriod
        self.scheduleName = scheduleName
        self.overrideDisplayDate = overrideDisplayDate
    }
    init(date: Date, displayPeriod: Period, scheduleName: String) {
        self.date = date
        self.displayPeriod = displayPeriod
        self.scheduleName = scheduleName
        self.overrideDisplayDate = nil
    }
}

struct EndTimeWidgetEntryView : View {
    var entry: EndTimeProvider.Entry
    let displayDate: Date
    
    init(entry: EndTimeProvider.Entry) {
        self.entry = entry
        self.displayDate = entry.overrideDisplayDate ?? entry.displayPeriod.getEndAsDate()
    }
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            VStack{
                // Day type name
                Text(entry.scheduleName)
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(entry.scheduleName)
                    .transition(.push(from: .top))
                
                
                // Timer
                Text(displayDate, style: .time)
                    .font(.system(size: 52, weight: .bold))
                    .fontWidth(.compressed)
                    .dynamicTypeSize(.medium)
                    .minimumScaleFactor(0.8)
                    .id(displayDate)
                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .transition(.push(from: .leading))
//                    .transition(.move(edge: .leading))
                    .transition(.asymmetric(insertion: .move(edge: .leading).animation(.easeIn(duration: 4)), removal: .move(edge: .trailing).combined(with: .opacity).animation(.easeOut(duration: 3))))
                
                Spacer()
                
                // Period information
                Text("\(entry.displayPeriod.name)\n\(entry.displayPeriod.startInLocale)-\(entry.displayPeriod.endInLocale)")
                    .lineLimit(2, reservesSpace: true)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(entry.displayPeriod.name)
                    .transition(.push(from: .bottom))

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        case .accessoryRectangular:
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
        default:
            Spacer()
        }
    }
}

struct EndTimeWidget: Widget {
    let kind: String = "EndTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EndTimeProvider()) { entry in
            if #available(iOS 17.0, *) {
                EndTimeWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                EndTimeWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Period End Time")
        .description("A widget to display at what time the current period ends, for when you want to use your own clock")
        #if os(iOS)
        .supportedFamilies([.systemSmall, .accessoryRectangular])
        #else
        .supportedFamilies([.accessoryRectangular])
        #endif
    }
}

#if os(iOS)
#Preview(as: .systemSmall) {
    EndTimeWidget()
} timeline: {
    EndTimeEntry(date: Calendar.current.date(bySettingHour: 12, minute: 55, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6", start: "12:39", end: "13:21"), scheduleName: "Regular Day")
    EndTimeEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6 → Period 7", start: "13:21", end: "13:25"), scheduleName: "Regular Day")
    EndTimeEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 7", start: "13:25", end: "14:07"), scheduleName: "Regular Day")
    EndTimeEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 8", start: "13:25", end: "14:07"), scheduleName: "Common Day")
}
#else
#Preview(as: .accessoryRectangular) {
    EndTimeWidget()
} timeline: {
    EndTimeEntry(date: Calendar.current.date(bySettingHour: 12, minute: 55, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6", start: "12:39", end: "13:21"), scheduleName: "Regular Day")
    EndTimeEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6 → Period 7", start: "13:21", end: "13:25"), scheduleName: "Regular Day")
    EndTimeEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 7", start: "13:25", end: "14:07"), scheduleName: "Regular Day")
    EndTimeEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 8", start: "13:25", end: "14:07"), scheduleName: "Common Day")
}
#endif
