//
//  DashWidgets.swift
//  DashWidgets
//
//  Created by Dalton Harrold on 2/8/24.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    let testPeriod = Period(name: "Testing Period", start: "8:00", end: "10:00")
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), displayPeriod: testPeriod)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), displayPeriod: testPeriod)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, displayPeriod: testPeriod)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let displayPeriod: Period
}

struct DashWidgetsEntryView : View {
    var entry: Provider.Entry
    
    @FetchRequest(sortDescriptors: [])
    private var fetchedDayTypes: FetchedResults<StoredDayType>
    

    var body: some View {
        VStack {
            Text("DashWidget")
            Text(fetchedDayTypes[0].periodsArray[0].name)
            Text("\(fetchedDayTypes[0].periodsArray[0].start) - \(fetchedDayTypes[0].periodsArray[0].end)")
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
    let previewPeriod = Period(name: "Testing Period", start: "8:00", end: "10:00")
    SimpleEntry(date: .now, displayPeriod: previewPeriod)
}
