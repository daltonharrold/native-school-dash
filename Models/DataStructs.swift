//
//  DataStructs.swift
//  NativeDash
//
//  Created by Dalton Harrold on 11/1/23.
//

import Foundation
import CoreData
import SwiftUI

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

extension Date {
    /// Gets the user clock
    func asUserClockTime(includeAmPm: Bool = true) -> String {
        let hour = Calendar.current.component(.hour, from: self)
        let minute = Calendar.current.component(.minute, from: self)
        if usesAMPM() {
            let newHour = hour%12 == 0 ? 12 : hour%12
            let amPm = !includeAmPm ? "" : hour < 12 ? " AM" : " PM"
            return "\(newHour):\(minute)\(amPm)"
        } else {
            let newHour = hour < 10 ? "0\(hour)" : "\(hour)"
            return "\(newHour):\(minute)"
        }
    }
}

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


