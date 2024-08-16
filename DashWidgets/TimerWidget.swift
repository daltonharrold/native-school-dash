//
//  TimerWidget.swift
//  DashWidgets
//
//  Created by Dalton Harrold on 2/8/24.
//

import WidgetKit
import SwiftUI
import OSLog

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

    func getTimeline(in timelineContext: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Logger.widget.info("Getting timeline for timer widget...")
        var entries: [TimerEntry] = []
        
        let context = PersistenceController.shared.backgroundContext
        let scheduleFetch = StoredScheduleOnDate.fetchRequest()
        
       
        do {
            let storedSchedules = try context.fetch(scheduleFetch)
            
            let currentDate = Date.now
            if let todaySchedule = storedSchedules.first(where: {
                Calendar.current.isDate($0.date!, equalTo: currentDate, toGranularity: .day)
            })?.schedule?.asDayType() {
                // Have an entry at midnight when schedules are needed
                let morningStart = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: .now)!
                let morningPeriod = Period(name: "Good morning", start: "00:00", end: todaySchedule.periods.first!.start)
                let morningEntry = TimerEntry(date: morningStart, displayPeriod: morningPeriod, scheduleName: todaySchedule.name, tomorrowSchoolStart: todaySchedule.periods.first!.getStartAsDate())
                entries.append(morningEntry)
                
                // Have an entry to countdown before school
                let countdownStart = todaySchedule.periods.first!.getStartAsDate().addingTimeInterval(TimeInterval(-15*60))
                let countdownPeriod = Period(name: "School starting...", start: countdownStart.asUserClockTime(includeAmPm: false), end: todaySchedule.periods.first!.start)
                let countdownEntry = TimerEntry(date: countdownStart, displayPeriod: countdownPeriod, scheduleName: todaySchedule.name)
                entries.append(countdownEntry)
                
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
                // Have an entry at the end of the day to have the start time of the next day shown
                if let tomorrowSchedule = storedSchedules.first(where: {
                    Calendar.current.isDate($0.date!, equalTo: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!, toGranularity: .day)
                })?.schedule?.asDayType() {
                    // At EOD, show tomorrow's start
                    let endOfDay: Date = todaySchedule.periods.last!.getEndAsDate()
                    let overnightPeriod: Period = Period(name: "Good night", start: todaySchedule.periods.last!.end, end:"00:00")
                    let overnightEntry = TimerEntry(date: endOfDay, displayPeriod: overnightPeriod, scheduleName: tomorrowSchedule.name, tomorrowSchoolStart: Calendar.current.date(byAdding: .day, value: 1, to: tomorrowSchedule.periods.first!.getStartAsDate())!)
                    
                    entries.append(overnightEntry)
                }
            } else {
                // Could not find entry for today, so re-fetch and then re-try to make timeline
                Logger.widget.info("Couldn't find stores for widget. Updating in background...")
                let config = URLSessionConfiguration.background(withIdentifier: "com.icloud-djharrold53.NativeDash.BGURLSession")
                config.sessionSendsLaunchEvents = true
                config.isDiscretionary = false
                

                let bgFetchUtil = BackgroundFetchUtil(withSessionConfig: config, daysAhead: 1)
                var numFetchesBack = 0
                
                bgFetchUtil.afterEveryFetch =  {
                    numFetchesBack += 1
                    if bgFetchUtil.error == nil {
                        Logger.background.info("Updated background from widget call")
                        if numFetchesBack == 2 {
                            completion(Timeline(entries: [], policy: .after(.now)))
                        }
                    } else {
                        Logger.background.error("Error when trying to update info in background for widget. \(bgFetchUtil.error!.description)")
                    }
                }
                bgFetchUtil.start()
                return
            }
        } catch {
            Logger.widget.error("Could not fetch from Core Data for widget timeline. \(error)")
        }
        
        let tomorrowMorning = Calendar.current.date(bySettingHour: 0, minute: 1, second: 0, of: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)!
        let timeline = Timeline(entries: entries, policy: .after(tomorrowMorning))
        Logger.widget.info("Successfuly refreshed timeline for timer widget")
        completion(timeline)
    }
}

struct TimerEntry: TimelineEntry {
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

struct DashWidgetsEntryView : View {
    var entry: TimerProvider.Entry
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
                
                if entry.tomorrowSchoolStart == nil {
                    Text(entry.displayPeriod.getEndAsDate(), style: .timer)
                        .font(.system(size: 52, weight: .bold))
                        .fontWidth(.compressed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(0)
                        .dynamicTypeSize(.medium)
                        .minimumScaleFactor(0.8)
                        .id(entry.displayPeriod.getStartAsDate())
                    //                        .transition(.push(from: .leading))
                    //                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .transition(.asymmetric(insertion: .move(edge: .leading).animation(.easeIn(duration: 4)), removal: .move(edge: .trailing).combined(with: .opacity).animation(.easeOut(duration: 3))))
                } else {
                    Text(entry.tomorrowSchoolStart!, style: .time)
                        .font(.system(size: 52, weight: .bold))
                        .fontWidth(.compressed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(0)
                        .dynamicTypeSize(.medium)
                        .minimumScaleFactor(0.8)
                        .id(entry.tomorrowSchoolStart!)
                    //                .transition(.push(from: .leading))
                    //                        .transition(.move(edge: .leading))
                        .transition(.asymmetric(insertion: .move(edge: .leading).animation(.easeIn(duration: 4)), removal: .move(edge: .trailing).combined(with: .opacity).animation(.easeOut(duration: 3))))
                }
                
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
            
        case .accessoryCircular:
            if entry.tomorrowSchoolStart == nil {
                ProgressView(timerInterval: entry.date...entry.displayPeriod.getEndAsDate(), countsDown: false){}currentValueLabel: {
                    Text(entry.displayPeriod.getEndAsDate(), style: .timer)
                        .lineLimit(1)
                }
                .tint(Color("AccentColor"))
                .progressViewStyle(.circular)
                #if os(watchOS)
                .widgetLabel(entry.displayPeriod.name)
                #endif
            } else {
                ProgressView(timerInterval: entry.date...entry.tomorrowSchoolStart!, countsDown: false){}currentValueLabel: {
                    Text(entry.tomorrowSchoolStart!, style: .time)
                        .lineLimit(1)
                }
                .tint(Color("AccentColor"))
                .progressViewStyle(.circular)
                #if os(watchOS)
                .widgetLabel(entry.displayPeriod.name)
                #endif
            }
        case .accessoryCorner:
            #if os(watchOS)
            if entry.tomorrowSchoolStart == nil {
                Text(entry.displayPeriod.getEndAsDate(), style: .timer)
                    .widgetCurvesContent(true)
                    .widgetLabel {
                        ProgressView(timerInterval: entry.date...entry.displayPeriod.getEndAsDate(), countsDown: false)
                            .tint(Color("AccentColor"))
                    }
            } else {
                Text(entry.tomorrowSchoolStart!, style: .time)
                    .widgetCurvesContent(true)
                    .widgetLabel {
                        ProgressView(timerInterval: entry.date...entry.tomorrowSchoolStart!, countsDown: false)
                            .tint(Color("AccentColor"))
                    }
            }
            #endif
        case .accessoryInline:
            if entry.tomorrowSchoolStart == nil {
                Text(entry.displayPeriod.getEndAsDate(), style: .timer) + Text("  |  ") + Text(entry.displayPeriod.name)
            } else  {
                Text(entry.tomorrowSchoolStart!, style: .time) + Text("  |  ") + Text(entry.displayPeriod.name)
            }
            
        default:
            Spacer()
        }
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
        #if os(iOS)
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
        #elseif os(watchOS)
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryCorner, .accessoryInline])
        #elseif os(macOS)
        .supportedFamilies([.systemSmall])
        #endif
    }
}

#if os(iOS) || os(macOS)
#Preview(as: .systemSmall) {
    TimerWidget()
} timeline: {
    TimerEntry(date: Calendar.current.date(bySettingHour: 12, minute: 55, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6", start: "12:39", end: "13:21"), scheduleName: "Regular Day")
    TimerEntry(date: Calendar.current.date(bySettingHour: 13, minute: 22, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6 → Period 7", start: "13:21", end: "13:25"), scheduleName: "Regular Day")
    TimerEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 7", start: "13:25", end: "14:07"), scheduleName: "Regular Day")
    TimerEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 8", start: "13:25", end: "14:07"), scheduleName: "Common Day")
}
#elseif os(watchOS)

#Preview(as: .accessoryRectangular) {
    TimerWidget()
} timeline: {
    TimerEntry(date: Calendar.current.date(bySettingHour: 12, minute: 55, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6", start: "12:39", end: "13:21"), scheduleName: "Regular Day")
    TimerEntry(date: Calendar.current.date(bySettingHour: 13, minute: 22, second: 00, of: .now)!, displayPeriod: Period(name: "Period 6 → Period 7", start: "13:21", end: "13:25"), scheduleName: "Regular Day")
    TimerEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 7", start: "13:25", end: "14:07"), scheduleName: "Regular Day")
    TimerEntry(date: Calendar.current.date(bySettingHour: 13, minute: 42, second: 00, of: .now)!, displayPeriod: Period(name: "Period 8", start: "13:25", end: "14:07"), scheduleName: "Common Day")
}
#endif
