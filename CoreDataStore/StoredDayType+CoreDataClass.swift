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
    func addToPeriodsFromArray(periods: [Period], context: NSManagedObjectContext) {
        for period in periods {
            let newStoredPeriod = StoredPeriod(context: context)
            newStoredPeriod.name = period.name
            newStoredPeriod.start = period.start
            newStoredPeriod.end = period.end
            self.addToPeriods(newStoredPeriod)
        }
    }
}
