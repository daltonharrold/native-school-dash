//
//  StoredDayType+CoreDataProperties.swift
//  NativeDash
//
//  Created by Dalton Harrold on 11/20/23.
//
//

import Foundation
import CoreData


extension StoredDayType {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredDayType> {
        return NSFetchRequest<StoredDayType>(entityName: "StoredDayType")
    }

    @NSManaged public var name: String?
    @NSManaged public var periods: NSOrderedSet?
    public var wrappedName: String {
        name ?? "Unknown schedule"
    }
    public var periodsArray: [Period] {
        var toReturn: [Period] = []
        for period in periods?.array as! [StoredPeriod] {
            toReturn.append(Period(name: period.wrappedName, start: period.wrappedStart, end: period.wrappedEnd))
        }
        return toReturn
    }
}

// MARK: Generated accessors for periods
extension StoredDayType {

    @objc(insertObject:inPeriodsAtIndex:)
    @NSManaged public func insertIntoPeriods(_ value: StoredPeriod, at idx: Int)

    @objc(removeObjectFromPeriodsAtIndex:)
    @NSManaged public func removeFromPeriods(at idx: Int)

    @objc(insertPeriods:atIndexes:)
    @NSManaged public func insertIntoPeriods(_ values: [StoredPeriod], at indexes: NSIndexSet)

    @objc(removePeriodsAtIndexes:)
    @NSManaged public func removeFromPeriods(at indexes: NSIndexSet)

    @objc(replaceObjectInPeriodsAtIndex:withObject:)
    @NSManaged public func replacePeriods(at idx: Int, with value: StoredPeriod)

    @objc(replacePeriodsAtIndexes:withPeriods:)
    @NSManaged public func replacePeriods(at indexes: NSIndexSet, with values: [StoredPeriod])

    @objc(addPeriodsObject:)
    @NSManaged public func addToPeriods(_ value: StoredPeriod)

    @objc(removePeriodsObject:)
    @NSManaged public func removeFromPeriods(_ value: StoredPeriod)

    @objc(addPeriods:)
    @NSManaged public func addToPeriods(_ values: NSOrderedSet)

    @objc(removePeriods:)
    @NSManaged public func removeFromPeriods(_ values: NSOrderedSet)

}

extension StoredDayType : Identifiable {

}
