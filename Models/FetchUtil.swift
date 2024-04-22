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


class FetchUtil {
    var context: NSManagedObjectContext
    var completion: ((Error?) -> ())? = nil {
        didSet {
            self.updater.completion = self.completion
        }
    }
    var error: FetchError? = nil
    var urlSession: URLSession
    var updater: UpdateOperation
    
    
    init(context: NSManagedObjectContext, urlSession: URLSession) {
        self.context = context
        self.urlSession = urlSession
        self.updater = UpdateOperation(context: context, urlSession: urlSession)
    }
    
    convenience init(context: NSManagedObjectContext) {
        let session = URLSession(configuration: .default)
        self.init(context: context, urlSession: session)
    }
    
    enum FetchError: Error {
        case cancelled
        case decodingError
        case notFetched
        case couldNotStore
        case other
    }
    
    
    class UpdateOperation: GenericAsyncOperation {
        let urlSession: URLSession
        var completion: ((Error?) -> ())? = nil
        
        let queue = OperationQueue()
        
        init(context: NSManagedObjectContext, urlSession: URLSession, completion: ( (Error?) -> Void)? = nil) {
            self.urlSession = urlSession
            self.completion = completion
            super.init(context: context)
        }
        
        private func handleCancel() {
            queue.cancelAllOperations()
            error = .cancelled
            state = .finished
        }
        
        override func main() {
            let fetchOperation = FetchOperation(numDatesInFuture: 6, context: context, urlSession: urlSession)
            let storeOperation = StoreOperation(context: context)
            
            
            let adapter = BlockOperation() { [unowned fetchOperation, unowned storeOperation] in
                if self.isCancelled {self.handleCancel(); return}
                guard fetchOperation.error == nil else {
                    self.error = fetchOperation.error
                    self.completion?(fetchOperation.error)
                    return
                }
                storeOperation.fetchedResponses = fetchOperation.fetchResponses
            }
            
            queue.addOperation(fetchOperation)
            
            adapter.addDependency(fetchOperation)
            queue.addOperation(adapter)
            
            storeOperation.addDependency(adapter)
            storeOperation.completionBlock = {
                self.error = storeOperation.error
                self.completion?(storeOperation.error)
                self.state = .finished
            }
            queue.addOperation(storeOperation)
            if self.isCancelled {
                handleCancel()
                return
            }
        }
    }
    
}
    
class GenericAsyncOperation: Operation {
    private let stateQueue = DispatchQueue(label: "com.icloud-djharrold53.NativeDash.AsyncOperationState", attributes: .concurrent)

    private(set) var context: NSManagedObjectContext
    var error: FetchUtil.FetchError? = nil
    
    init(context: NSManagedObjectContext) {
        self.context = context
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
    let fo = FetchOperation(numDatesInFuture: 6, context: PersistenceController.shared.container.viewContext, urlSession: URLSession.shared)
    let queue = OperationQueue()
    print("Starting Operation")
    queue.addOperations([fo], waitUntilFinished: true)
    print("Finished Operation")
    print("fo: \(String(describing: fo.fetchResponses))")
}

class FetchOperation: GenericAsyncOperation {
    var fetchResponses: [FetchedResponse]? = nil
    let dates: [Date]
    let urlSession: URLSession
    
    init(dates: [Date], context: NSManagedObjectContext, urlSession: URLSession) {
        self.dates = dates
        self.urlSession = urlSession
        super.init(context: context)
    }
    
    convenience init(numDatesInFuture: Int, context: NSManagedObjectContext, urlSession: URLSession) {
        var dates: [Date] = []
        for num in 0...numDatesInFuture {
            dates.append(Calendar.current.date(byAdding: .day, value: num, to: .now)!)
        }
        self.init(dates: dates, context: context, urlSession: urlSession)
    }
    
    override func main() {
        if isCancelled {
            state = .finished
            super.error = .cancelled
            return
        }
        
        var subjectCollection: [FetchedResponse] = []
        let urlDownloadQueue = DispatchQueue(label: "com.icloud-djharrold53.NativeDash.UrlDownloadQueue")
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
        // Check if cancelled
        if self.isCancelled {self.state = .finished; super.error = .cancelled; return}
        
        fetchRequests.forEach {(request) in
            print("Fetch started for \(request.key.ISO8601Format())")
            urlDownloadGroup.enter()
        
            urlSession.dataTask(with: request.value, completionHandler: { (data, response, error) in
    //            print("Data" + String(describing: data) + "Response:" + String(describing: response) + "error" + String(describing: error))
                guard let data = data,
                    let subject = try? JSONDecoder().decode(ApiResponse.self, from: data) else {
                    // handle error
                    urlDownloadQueue.async {
                        print("[NativeDash]: Error in decoding fetchedJSON. \(String(describing: error))")
                        super.error = .decodingError
                        urlDownloadGroup.leave()
                    }
                    return
                }
            
                urlDownloadQueue.async {
                    if self.isCancelled {self.state = .finished; super.error = .cancelled; return}
                    let returnData = FetchedResponse(onDate: request.key, response: subject)
                    print("Fetch completed for \(returnData.onDate.ISO8601Format())")
                    subjectCollection.append(returnData)
                    urlDownloadGroup.leave()
                }
            }).resume()
            
        }

        urlDownloadGroup.notify(queue: DispatchQueue.global()) {
            self.fetchResponses = subjectCollection
            self.state = .finished
        }
    }
}

class StoreOperation: GenericAsyncOperation {
    var fetchedResponses: [FetchedResponse]? = nil
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    private func rollback() {
        print("Store operation cancelled. Rolling back...")
        context.rollback()
        super.error = .cancelled
        self.state = .finished
    }
    
    override func main() {
        if self.isCancelled {rollback(); return}
        
        guard let fetchedResponses = fetchedResponses, !fetchedResponses.isEmpty else {
            print("Responses not fetched for storing.")
            super.error = .notFetched
            self.state = .finished
            return
        }
        
        print("Updating StoredDayTypes...")
        // Update StoredDayTypes
        do {
            // Get current data from Core Data to manage it
            let storedDayTypes = try context.fetch(StoredDayType.fetchRequest())
            
            // Delete previous local stores
            storedDayTypes.forEach(context.delete)
                
            // Store new schedules that have been fetched
            for schedule in fetchedResponses.first!.response.dayTypes {
                _ = schedule.toStoredDayType(context: context)
            }
                
            if self.isCancelled {rollback(); return}
            
        } catch {
            print("[NativeDash]: failed to update StoredDayTypes. \(error)")
            context.rollback()
            super.error = .couldNotStore
        }
        
        print("Updating StoredScheduleOnDate...")
        // Insert next week's schedules into stores
        do {
            if self.isCancelled {rollback(); return}
            let storedScheduleOnDates = try context.fetch(StoredScheduleOnDate.fetchRequest())
            let storedDayTypes = try context.fetch(StoredDayType.fetchRequest())
            
            // Delete stores for past dates
            storedScheduleOnDates.filter({schedule in
                return schedule.date!.timeIntervalSinceNow < 0 && !Calendar.current.isDateInToday(schedule.date!)
            }).forEach(context.delete)
            
            
            for scheduleResponse in fetchedResponses {
                if self.isCancelled {rollback(); return}
  
                // Delete old store for looped date
                if let oldStore = storedScheduleOnDates.first(where: {Calendar.current.isDate($0.date!, inSameDayAs: scheduleResponse.onDate)}) {
                    context.delete(oldStore)
                }
                
                // Insert schedule into Core Data
                let storedSchedule = StoredScheduleOnDate(context: context)
                storedSchedule.date = scheduleResponse.onDate
                let possibleSchedule = storedDayTypes.first(where: {$0.name == scheduleResponse.response.dayTypeOnDate.name})
                storedSchedule.schedule = possibleSchedule ?? storedDayTypes.first
            }
            
            if self.isCancelled {rollback(); return}
            try context.save()
        } catch {
            print("[NativeDash]: failed to update StoredScheduleOnDate. \(error)")
            context.rollback()
            super.error = .couldNotStore
        }
        
        print("Finished updating stores!")
        self.state = .finished
    }
}
