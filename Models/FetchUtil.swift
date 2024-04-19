//
//  FetchUtil.swift
//  NativeDash
//
//  Created by Dalton Harrold on 4/15/24.
//

import Foundation
import CoreData
import SwiftUI

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


struct FetchUtil {
    
}


class GenericAsyncOperation: Operation {
    private let stateQueue = DispatchQueue(label: "com.icloud-djharrold53.NativeDash.AsyncOperationState", attributes: .concurrent)

    fileprivate let viewContext: NSManagedObjectContext
    let dayOffset: Int
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext, dayOffset: Int = 0) {
        self.viewContext = context
        self.dayOffset = dayOffset
    }
    
    enum State: String {
        case ready
        case executing
        case finished
        
        var keyPath: String {
            return "is\(rawValue.capitalized)"
        }
    }
    
    private var _state = State.ready
    public var state: State {
        get {
            stateQueue.sync {
                return _state
            }
        }
        set {
            let oldValue = state
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
            stateQueue.sync(flags: .barrier) {
                _state = newValue
            }
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
    
    
    override var isFinished: Bool {
        state == .finished
    }
    
    override var isExecuting: Bool {
        state == .executing
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override func start() {
        if isCancelled {
            state = .finished
            return
        }
        state = .executing
        main()
    }
    
}
public func testing() {
    let fo = FetchOperation()
    let queue = OperationQueue()
    print("Starting Operation")
    queue.addOperations([fo], waitUntilFinished: true)
    print("Finished Operation")
    print("Operation outputs:" + (fo.fetchResponse?.response.name ?? "no output..."))
}

class FetchOperation: GenericAsyncOperation {
    var fetchResponse: FetchedResponse?
    
    override func main() {
        // Create ability to hold thread until fetch complete
        if isCancelled {self.state = .finished; return}
        let sephamore = DispatchSemaphore(value: 0)
        Task(priority: .medium) {
            do {
                
                fetchResponse = try await getDayTypeFromApi()
                self.state = .finished
            } catch {
                print("[NativeDash]: failed to get today's schedule in FetchOperation. \(error)")
                fetchResponse = nil
            }
        }
        sephamore.wait()
    }
}

func downloadUrls(dates: [Date], completion: @escaping ([FetchedResponse]) -> Void) {
    var subjectCollection: [FetchedResponse] = []
    let urlDownloadQueue = DispatchQueue(label: "com.urlDownloader.urlqueue")
    let urlDownloadGroup = DispatchGroup()

    var fetchRequests: Dictionary<Date, URLRequest> = [:]
    
    for date in dates {
        let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: date)
        if let url = URL(string: "\(ProcessInfo.processInfo.environment["API_ENDPOINT"]!)/schools/\( ProcessInfo.processInfo.environment["SCHOOL_ID"]!)?includes=dayTypeOnDate&day=\(calendarDate.day!)&month=\(calendarDate.month!)&year=\(calendarDate.year!)") {
            var req = URLRequest(url: url)
            req.setValue(ProcessInfo.processInfo.environment["API_KEY"], forHTTPHeaderField: "authorization")
            fetchRequests[date] = req
        }
    }
    
    fetchRequests.forEach {(request) in
        print("Fetch started for \(request.key.ISO8601Format())")
        urlDownloadGroup.enter()
    
        URLSession.shared.dataTask(with: request.value, completionHandler: { (data, response, error) in
//            print("Data" + String(describing: data) + "Response:" + String(describing: response) + "error" + String(describing: error))
            guard let data = data,
                let subject = try? JSONDecoder().decode(ApiResponse.self, from: data) else {
                // handle error
                urlDownloadQueue.async {
                    print("[NativeDash]: Error in decoding fetchedJSON. \(String(describing: error))")
                    urlDownloadGroup.leave()
                }
                return
            }
        
            urlDownloadQueue.async {
                let returnData = FetchedResponse(onDate: request.key, response: subject)
                print("Fetch completed for \(returnData.onDate.ISO8601Format())")
                subjectCollection.append(returnData)
                urlDownloadGroup.leave()
            }
        }).resume()
    }

    urlDownloadGroup.notify(queue: DispatchQueue.global()) {
        completion(subjectCollection)
    }
}
