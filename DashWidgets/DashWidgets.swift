//
//  DashWidgets.swift
//  DashWidgets
//
//  Created by Dalton Harrold on 2/8/24.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
//    let testPeriod = Period(name: "Testing Period", start: "8:00", end: "10:00")
    
    func placeholder(in context: Context) -> SimpleEntry {
        // Feb 9, 2024 13:15:00 CST
        SimpleEntry(date: Date(timeIntervalSince1970: TimeInterval(1707506100)))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // Feb 9, 2024 13:15:00 CST
        let entry = SimpleEntry(date: Date(timeIntervalSince1970: TimeInterval(1707506100)))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for minuteOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            print(entryDate)
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct DashWidgetsEntryView : View {
    @Environment(\.managedObjectContext) private var viewContext
    var entry: Provider.Entry
    
    @FetchRequest(sortDescriptors: [])
    private var storedScheduleOnDate: FetchedResults<StoredScheduleOnDate>
    
    
    var todaySchedule: DayType? {
        storedScheduleOnDate.first(where: {
            Calendar.current.isDate($0.date!, equalTo: entry.date, toGranularity: .day)
        })?.schedule?.asDayType()
    }
    
    var displayPeriod: Period? {
        todaySchedule == nil ? nil : getNextPeriod(schedule: todaySchedule!, atDate: entry.date)
    }
    
    var timeLeftInPeriod: Duration {
        Duration.seconds(getSecondsToPeriodStartEnd(period: displayPeriod, isEnd: true, atDate: entry.date))
    }
    
    var progress: CGFloat {
        let secondsToStart = getSecondsToPeriodStartEnd(period: displayPeriod, isEnd: false, atDate: entry.date)
        return CGFloat(secondsToStart) / CGFloat(Int(timeLeftInPeriod.components.seconds) + secondsToStart)
    }
    
    

    var body: some View {
        VStack {
            Text(entry.date, style: .time)
            if displayPeriod != nil {
                ZStack {
                    Circle()
                        .stroke(Color("EmptyAccentColor"), style: StrokeStyle(lineWidth: 20))
                    Circle()
                        .rotation(Angle(degrees:(-(360*progress)-90)))
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color("AccentColor"),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    Text("\((timeLeftInPeriod.components.seconds / 60) + 1)")
                        .fontWeight(.semibold)
                        .font(.title)
                }
            } else {
                Text("Loading...")
            }
        }
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
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#Preview(as: .systemSmall) {
    DashWidgets()
} timeline: {
//    let previewPeriod = Period(name: "Testing Period", start: "8:00", end: "10:00")
    SimpleEntry(date: .now)
}
