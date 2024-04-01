//
//  DataStructs.swift
//  NativeDash
//
//  Created by Dalton Harrold on 11/1/23.
//

import Foundation
import CoreData

public struct DayType: Decodable {
    let name: String
    var periods: [Period]
    func to12HourTime() -> DayType {
        var newDayType = DayType(name: self.name, periods: [])
        for period in self.periods {
            let newStartHour = (Int(period.start.split(separator: ":")[0]) ?? 0) % 12
            let newEndHour = (Int(period.end.split(separator: ":")[0]) ?? 0) % 12
            let newStart = "\(newStartHour == 0 ? 12 : newStartHour):\(period.start.split(separator: ":")[1])"
            let newEnd = "\(newEndHour == 0 ? 12 : newEndHour):\(period.end.split(separator: ":")[1])"
            newDayType.periods.append(Period(name: period.name, start: newStart, end: newEnd))
        }
        return newDayType
    }
    func toStoredDayType(context: NSManagedObjectContext) -> StoredDayType {
        let newDayType = StoredDayType(context: context)
        newDayType.name = self.name
        newDayType.addToPeriodsFromArray(periods: self.periods, context: context)
        return newDayType
    }
}

public struct Period: Decodable {
    var name: String
    var start: String
    var end: String
    
    var startInLocale: String {
        if usesAMPM() {
            let hrMin = start.split(separator: ":")
            var newHr = Int(hrMin[0])! % 12
            newHr = newHr == 0 ? 12 : newHr
            return "\(newHr):\(hrMin[1])"
        } else {
            return start
        }
    }
    
    var endInLocale: String {
        if usesAMPM() {
            let hrMin = end.split(separator: ":")
            var newHr = Int(hrMin[0])! % 12
            newHr = newHr == 0 ? 12 : newHr
            return "\(newHr):\(hrMin[1])"
        } else {
            return end
        }
    }
    
    public func getStartAsDate() -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd ZZZZ"
        let yearMonthDay = formatter.string(from: .now)
        formatter.dateFormat = "yyyy/MM/dd ZZZZ HH:mm:ss"
        return formatter.date(from: "\(yearMonthDay) \(start):00")!
    }
    
    public func getEndAsDate() -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd ZZZZ"
        let yearMonthDay = formatter.string(from: .now)
        formatter.dateFormat = "yyyy/MM/dd ZZZZ HH:mm:ss"
        return formatter.date(from: "\(yearMonthDay) \(end):00")!
    }
}

private func usesAMPM() -> Bool {
    let locale = NSLocale.current
    let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale)!
    if dateFormat.contains("a") {
        return true
    }
    else {
        return false
    }
}

public struct ApiResponse: Decodable {
    let dayTypeOnDate: DayType
    let name: String
    let _id: String
    let dayTypes: [DayType]
}

public struct FetchedResponse {
    let onDate: Date
    let response: ApiResponse
    init(onDate: Date, response: ApiResponse) {
        self.onDate = onDate
        self.response = response
    }
}

//public class YearMonthDay {
//    let year: Int
//    let month: Int
//    let day: Int
//    func asDateComponents() -> DateComponents {
//        return DateComponents(year: year, month: month, day: day)
//    }
//    
//    func asDate() -> Date {
//        var date = Date()
//        date = Calendar.current.date(bySetting: .year, value: self.year, of: date)!
//        date = Calendar.current.date(bySetting: .month, value: self.month, of: date)!
//        date = Calendar.current.date(bySetting: .day, value: self.day, of: date)!
//        return date
//    }
//
//    init(year: Int, month: Int, day: Int) {
//        self.year = year
//        self.month = month
//        self.day = day
//    }
//    init(components: DateComponents) {
//        self.year = components.year!
//        self.month = components.month!
//        self.day = components.day!
//    }
//    init(date: Date) {
//        self.year = Calendar.current.component(.year, from: date)
//        self.month = Calendar.current.component(.month, from: date)
//        self.day = Calendar.current.component(.day, from: date)
//    }
//}

// Get the number of seconds to the start or end of current period. Time must be between given period start or end
// If isEnd = true, will return time to end, else will return time to start
func getSecondsToPeriodStartEnd(period: Period?, isEnd: Bool, atDate: Date = .now) -> Int {
    let nextPeriodEndTime = (isEnd ? (period?.end ?? "00:00") : (period?.start ?? "00:00")) + ":00"
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd ZZZZ"
    let yearMonthDay = formatter.string(from: atDate)
    formatter.dateFormat = "yyyy/MM/dd ZZZZ HH:mm:ss"
    let endOfPeriod = formatter.date(from: "\(yearMonthDay) \(nextPeriodEndTime)")
    let diff = abs(endOfPeriod!.timeIntervalSinceNow)
    return Int(diff)
}

func getNextPeriod(schedule: DayType, atDate: Date = .now) -> Period? {
    let formatter = DateFormatter()
    // We need to be able to make a date object setting the end of the period as the time, so we need to get the current date and re-input it in the date constructor
    formatter.dateFormat = "yyyy/MM/dd ZZZZ"
    let yearMonthDay = formatter.string(from: atDate)
    formatter.dateFormat = "yyyy/MM/dd ZZZZ HH:mm:ss"
    
    for (index, period) in schedule.periods.enumerated() {
        // If period start is in future (Currently in a passing period)
        let timeSincePeriodStart = formatter.date(from: "\(yearMonthDay) \(period.start):00")!.timeIntervalSinceNow
        let timeSincePeriodEnd = formatter.date(from: "\(yearMonthDay) \(period.end):00")!.timeIntervalSinceNow
        
        // If period start is in future (Currently in passing period)
        if timeSincePeriodStart > 0 {
            if index == 0 {
                // If before school, do not display period ring
                return nil
            }
            return Period(name: "\(schedule.periods[index-1].name) → \(period.name)", start: schedule.periods[index-1].end, end: period.start)
        } 
        // If period end is in future (Currently in a period)
        else if timeSincePeriodEnd > 0 {
            return period
        }
        
        // If no period detected and loop is on last period in schedule, assume after-school hours
        // and do not display period ring timer
        if index+1 == schedule.periods.count {
            return nil
        }
    }
    return nil
}

public func getDayTypeFromApi(onDay: Date = .now) async throws -> FetchedResponse? {
    let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: onDay)
    if let url = URL(string: "\(ProcessInfo.processInfo.environment["API_ENDPOINT"]!)/schools/\( ProcessInfo.processInfo.environment["SCHOOL_ID"]!)?includes=dayTypeOnDate&day=\(calendarDate.day!)&month=\(calendarDate.month!)&year=\(calendarDate.year!)") {
        var request = URLRequest(url: url)
        request.setValue(ProcessInfo.processInfo.environment["API_KEY"], forHTTPHeaderField: "authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            do {
                let jsonData = jsonString.data(using: .utf8)!
                let response = try JSONDecoder().decode(ApiResponse.self, from: jsonData)
                let returnData = FetchedResponse(onDate: onDay, response: response)
                return returnData
            } catch {
                print("[NativeDash]: Error while decoding JSON. \(error)")
            }
        }
    }
    return nil
}

public func updateScheduleStores(viewContext: NSManagedObjectContext) async {
    var todayFetch: FetchedResponse?
    do {
        todayFetch = try await getDayTypeFromApi()
    } catch {
        print("[NativeDash]: failed to get today's schedule in updateScheduleStores. \(error)")
        todayFetch = nil
    }
    
    // Update StoredDayTypes
    do {
        // Get current data from Core Data to manage it
        let storedDayTypes = try viewContext.fetch(StoredDayType.fetchRequest())

        if todayFetch != nil {
            // Delete previous local stores
            storedDayTypes.forEach(viewContext.delete)
            
            // Store new schedules that have been fetched
            for schedule in todayFetch!.response.dayTypes {
                _ = schedule.toStoredDayType(context: viewContext)
            }
            
            try viewContext.save()
        }
    } catch {
        print("[NativeDash]: failed to update StoredDayTypes. \(error)")
    }
    
    // Fetch schedules for next week
    var nextWeekFetches: [FetchedResponse?] = [todayFetch]
    for i in 1...6 {
        do {
            guard let fetchDate = Calendar.current.date(byAdding: .day, value: i, to: .now) 
            else {
                nextWeekFetches.append(nil)
                continue
            }
            
            let scheduleOnDate = try await getDayTypeFromApi(onDay: fetchDate)
            nextWeekFetches.append(scheduleOnDate)
        } catch {
            print("[NativeDash]: failed to get week's schedule in updateScheduleStores. \(error)")
            nextWeekFetches.append(nil)
        }
    }
    // Insert next week's schedules into stores
    do {
        let storedScheduleOnDates = try viewContext.fetch(StoredScheduleOnDate.fetchRequest())
        let storedDayTypes = try viewContext.fetch(StoredDayType.fetchRequest())
        
        // Delete stores for past dates
        storedScheduleOnDates.filter({schedule in
            return schedule.date!.timeIntervalSinceNow < 0 && !Calendar.current.isDateInToday(schedule.date!)
        }).forEach(viewContext.delete)
        
        
        for fetchedScheduleOnDate in nextWeekFetches {
            guard let scheduleResponse = fetchedScheduleOnDate else {continue}
            // Delete old store for looped date
            if let oldStore = storedScheduleOnDates.first(where: {Calendar.current.isDate($0.date!, inSameDayAs: scheduleResponse.onDate)}) {
                viewContext.delete(oldStore)
            }
            
            // Insert schedule into Core Data
            let storedSchedule = StoredScheduleOnDate(context: viewContext)
            storedSchedule.date = scheduleResponse.onDate
            let possibleSchedule = storedDayTypes.first(where: {$0.name == scheduleResponse.response.dayTypeOnDate.name})
            storedSchedule.schedule = possibleSchedule ?? storedDayTypes.first
        }
        
        try viewContext.save()
    } catch {
        print("[NativeDash]: failed to update StoredScheduleOnDate. \(error)")
    }
}
