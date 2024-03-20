//
//  StoredDayType+CoreDataClass.swift
//  NativeDash
//
//  Created by Dalton Harrold on 11/20/23.
//
//

import Foundation
import CoreData

// Country
@objc(StoredDayType)
public class StoredDayType: NSManagedObject {
    public var wrappedName: String {
        name ?? "Unknown schedule"
    }
    
    func addToPeriodsFromArray(periods: [Period], context: NSManagedObjectContext) {
        for period in periods {
            let newStoredPeriod = StoredPeriod(context: context)
            newStoredPeriod.name = period.name
            newStoredPeriod.start = period.start
            newStoredPeriod.end = period.end
            self.addToPeriods(newStoredPeriod)
        }
    }
    
    func asDayType() -> DayType {
        return DayType(name: self.wrappedName, periods: self.periodsArray)
    }
    
    func to12HourTime() -> DayType {
        var newDayType = DayType(name: self.name ?? "Unknown period", periods: [])
        for period in self.periods?.array as! [Period] {
            let newStartHour = (Int(period.start.split(separator: ":")[0]) ?? 0) % 12
            let newEndHour = (Int(period.end.split(separator: ":")[0]) ?? 0) % 12
            let newStart = "\(newStartHour == 0 ? 12 : newStartHour):\(period.start.split(separator: ":")[1])"
            let newEnd = "\(newEndHour == 0 ? 12 : newEndHour):\(period.end.split(separator: ":")[1])"
            newDayType.periods.append(Period(name: period.name, start: newStart, end: newEnd))
        
        }
        return newDayType
    }

    public var periodsArray: [Period] {
        var toReturn: [Period] = []
        let debug = (type(of: periods))
        for period in periods?.array as! [StoredPeriod] {
            toReturn.append(Period(name: period.wrappedName, start: period.wrappedStart, end: period.wrappedEnd))
        }
        return toReturn
    }
}
