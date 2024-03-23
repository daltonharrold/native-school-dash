//
//  DashWidgets.swift
//  DashWidgets
//
//  Created by Dalton Harrold on 2/8/24.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    let placeholderTimeInSixthPeriod = Calendar.current.date(bySettingHour: 12, minute: 55, second: 00, of: .now)!
    let placeholderSixthPeriod = Period(name: "Period 6", start: "12:39", end: "13:21")
    
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: placeholderTimeInSixthPeriod, displayPeriod: placeholderSixthPeriod, scheduleName: "Regular Day")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }

        let entry = SimpleEntry(date: placeholderTimeInSixthPeriod, displayPeriod: placeholderSixthPeriod, scheduleName: "Regular Day")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        let viewContext = PersistenceController.shared.container.viewContext
        let scheduleFetch = StoredScheduleOnDate.fetchRequest()
        
        
        do {
            let storedSchedules = try viewContext.fetch(scheduleFetch)
            
            let currentDate = Date()
            if let todaySchedule = storedSchedules.first(where: {
                Calendar.current.isDate($0.date!, equalTo: currentDate, toGranularity: .day)
            })?.schedule?.asDayType() {
                for period in todaySchedule.periods {
                    let periodStart = period.getStartAsDate()
                    
                    let entry = SimpleEntry(date: periodStart, displayPeriod: period, scheduleName: todaySchedule.name)
                    entries.append(entry)
                }
            }
        } catch {
            fatalError("Could not fetch from Core Data for widget timeline. \(error)")
        }
        

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let displayPeriod: Period
    let scheduleName: String
}

struct DashWidgetsEntryView : View {
    var entry: Provider.Entry
    

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

struct DashWidgets: Widget {
    let kind: String = "DashWidgets"
    let persistenceController = PersistenceController.shared

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                DashWidgetsEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                DashWidgetsEntryView(entry: entry)
                    .padding()
                    .background()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
        .configurationDisplayName("Time Left in Period")
        .description("A widget to display how much time is left in the current period at a glance.")
    }
}

#Preview(as: .systemSmall) {
    DashWidgets()
} timeline: {
    SimpleEntry(date: Calendar.current.date(bySettingHour: 12, minute: 55, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6", start: "12:39", end: "13:21"), scheduleName: "Regular Day")
    SimpleEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 7", start: "13:25", end: "14:07"), scheduleName: "Regular Day")
    SimpleEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 7", start: "13:25", end: "14:07"), scheduleName: "Common Day")
}
