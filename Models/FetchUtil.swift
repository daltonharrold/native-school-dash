//
//  FetchUtil.swift
//  NativeDash
//
//  Created by Dalton Harrold on 4/15/24.
//

import Foundation
import CoreData

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

