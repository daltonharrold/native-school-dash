//
//  StoredPeriod+CoreDataProperties.swift
//  NativeDash
//
//  Created by Dalton Harrold on 11/20/23.
//
//

import Foundation
import CoreData


extension StoredPeriod {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredPeriod> {
        return NSFetchRequest<StoredPeriod>(entityName: "StoredPeriod")
    }

    @NSManaged public var name: String?
    @NSManaged public var start: String?
    @NSManaged public var end: String?
    @NSManaged public var schedule: StoredDayType?

    public var wrappedName: String {
        name ?? "Unknown period"
    }
    public var wrappedStart: String {
        start ?? "00:00"
    }
    public var wrappedEnd: String {
        end ?? "00:00"
    }
}

extension StoredPeriod : Identifiable {

}
