//
//  StoredDayType+CoreDataProperties.swift
//  NativeDash
//
//  Created by Dalton Harrold on 5/9/24.
//
//

import Foundation
import CoreData


extension StoredDayType {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredDayType> {
        return NSFetchRequest<StoredDayType>(entityName: "StoredDayType")
    }

    @NSManaged public var name: String?
    @NSManaged public var periods: NSSet?
    @NSManaged public var daysWithSchedule: NSSet?

}

// MARK: Generated accessors for periods
extension StoredDayType {

    @objc(addPeriodsObject:)
    @NSManaged public func addToPeriods(_ value: StoredPeriod)

    @objc(removePeriodsObject:)
    @NSManaged public func removeFromPeriods(_ value: StoredPeriod)

    @objc(addPeriods:)
    @NSManaged public func addToPeriods(_ values: NSSet)

    @objc(removePeriods:)
    @NSManaged public func removeFromPeriods(_ values: NSSet)

}

// MARK: Generated accessors for daysWithSchedule
extension StoredDayType {

    @objc(addDaysWithScheduleObject:)
    @NSManaged public func addToDaysWithSchedule(_ value: StoredScheduleOnDate)

    @objc(removeDaysWithScheduleObject:)
    @NSManaged public func removeFromDaysWithSchedule(_ value: StoredScheduleOnDate)

    @objc(addDaysWithSchedule:)
    @NSManaged public func addToDaysWithSchedule(_ values: NSSet)

    @objc(removeDaysWithSchedule:)
    @NSManaged public func removeFromDaysWithSchedule(_ values: NSSet)

}

extension StoredDayType : Identifiable {

}
