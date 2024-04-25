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

enum FetchError: Error {
    case cancelled
    case decodingError
    case notFetched
    case couldNotStore
    case noPlist
    case other
}

extension FetchError: CustomStringConvertible {
    var description: String {
        switch self {
        case .cancelled:
            return "Operation cancelled by user or system"
        case .decodingError:
            return "There was an error decoding fetched JSON content"
        case .notFetched:
            return "The content was not fetched from the API and could not be stored"
        case .couldNotStore:
            return "There was an error storing the fetched data in Core Data. (Rolled back)"
        case .noPlist:
            return "There was an error trying to read plist environment variables"
        default:
            return "An unknown error occured when fetching"
        }
    }
}

class FetchUtil {
    var context: NSManagedObjectContext
    var completion: ((Error?) -> ())? = nil {
        didSet {
            self.updateOp.completion = self.completion
        }
    }
    var error: FetchError? = nil
    var urlSession: URLSession
    private var updateOp: UpdateOperation
    private let updateOpQueue = OperationQueue()
    
    static func getEndpointUrl(onDate: Date) throws -> URL {
        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else { throw FetchError.noPlist }
        guard let env = infoDictionary["LSEnvironment"] as? Dictionary<String, Any> else { throw FetchError.noPlist}
        guard let apiEndpoint: String = env["API_ENDPOINT"] as? String else { throw FetchError.noPlist }
        guard let schoolID: String = env["SCHOOL_ID"] as? String else { throw FetchError.noPlist }
        
        
        let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: onDate)
        if let url = URL(string: "https://\(apiEndpoint)/schools/\( schoolID)?includes=dayTypeOnDate&day=\(calendarDate.day!)&month=\(calendarDate.month!)&year=\(calendarDate.year!)") {
            return url
        } else {
            throw FetchError.other
        }
    }
    
    static func getApiKey() throws -> String {
        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else { throw FetchError.noPlist }
        guard let env = infoDictionary["LSEnvironment"] as? Dictionary<String, Any> else { throw FetchError.noPlist}
        guard let apiKey: String = env["API_KEY"] as? String else { throw FetchError.noPlist }
        return apiKey
    }
    
    var updater: UpdaterInterface
    
    struct UpdaterInterface {
        let op: Operation
        let q: OperationQueue
        func start() {
            q.addOperation(op)
        }
        func cancel() {
            op.cancel()
        }
    }
    
    init(context: NSManagedObjectContext, urlSession: URLSession) {
        self.context = context
        self.urlSession = urlSession
        self.updateOp = UpdateOperation(context: context, urlSession: urlSession)
        self.updater = UpdaterInterface(op: updateOp, q: updateOpQueue)
    }
    
    convenience init(context: NSManagedObjectContext) {
        let session = URLSession(configuration: .default)
        self.init(context: context, urlSession: session)
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
            error = FetchError.cancelled
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
    
    
    
//    /// Used for background tasks, where the app must be lightweight instead of fast. This does not store to Core Data.
//    /// This function uses async/await API instead of OperationQueues, meaning all requests run on one thread
//    static func backgroundApiGet(onDate: Date = .now, urlSession: URLSession) async throws -> FetchedResponse? {
//        // Load environment varibles
//        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else { throw FetchError.noPlist }
//        guard let env = infoDictionary["LSEnvironment"] as? Dictionary<String, Any> else { throw FetchError.noPlist}
//        guard let apiEndpoint: String = env["apiEndpoint"] as? String else { throw FetchError.noPlist }
//        guard let apiKey: String = env["apiKey"] as? String else { throw FetchError.noPlist }
//        guard let schoolID: String = env["schoolID"] as? String else { throw FetchError.noPlist }
//        
//        
//        let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: onDate)
//        if let url = URL(string: "https://\(apiEndpoint)/schools/\( schoolID)?includes=dayTypeOnDate&day=\(calendarDate.day!)&month=\(calendarDate.month!)&year=\(calendarDate.year!)") {
//            var request = URLRequest(url: url)
//            request.setValue(apiKey, forHTTPHeaderField: "authorization")
//            let (data, _) = try await urlSession.data(for: request)
//            
//            if let jsonString = String(data: data, encoding: .utf8) {
//                do {
//                    let jsonData = jsonString.data(using: .utf8)!
//                    let response = try JSONDecoder().decode(ApiResponse.self, from: jsonData)
//                    let returnData = FetchedResponse(onDate: onDate, response: response)
//                    return returnData
//                } catch {
//                    print("[NativeDash]: Error while decoding JSON. \(error)")
//                    throw FetchError.noPlist
//                }
//            }
//        }
//        return nil
//    }

}
    
class GenericAsyncOperation: Operation {
    private let stateQueue = DispatchQueue(label: "com.icloud-djharrold53.NativeDash.AsyncOperationState", attributes: .concurrent)

    let context: NSManagedObjectContext
    var error: FetchError? = nil
    
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
            guard let envDict = Bundle.main.object(forInfoDictionaryKey: "LSEnvironment") as? Dictionary<String, String> else {
                fatalError("Could not get plist Env values")
            }
            if let url = URL(string: "https://\(envDict["API_ENDPOINT"]!)/schools/\( envDict["SCHOOL_ID"]!)?includes=dayTypeOnDate&day=\(calendarDate.day!)&month=\(calendarDate.month!)&year=\(calendarDate.year!)") {
                
                var req = URLRequest(url: url)
                req.setValue(envDict["API_KEY"]!, forHTTPHeaderField: "authorization")
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

class BackgroundFetchUtil: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    var context: NSManagedObjectContext
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    static let shared = BackgroundFetchUtil(context: PersistenceController.shared.container.viewContext)
    

    
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Download finished: \(location.absoluteString)")
        guard let data = try? Data(contentsOf: location) else {return}
        guard let urlResponse = downloadTask.response else {return}
        try? BackgroundFetchUtil.storeRawFetch(data: (data, urlResponse), context: self.context, storesDayType: true)
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download error: \(String(describing: error))")
        }
    }
    
    static func storeRawFetch(data: (Data, URLResponse), context: NSManagedObjectContext, storesDayType: Bool) throws {
        
        var response: FetchedResponse?
        
        let urlComponents = URLComponents(url: data.1.url!, resolvingAgainstBaseURL: true)!
        var components = DateComponents()
        components.day = Int((urlComponents.queryItems?.first(where: { $0.name == "day" })?.value)!)
        components.month = Int((urlComponents.queryItems?.first(where: { $0.name == "month" })?.value)!)
        components.year = Int((urlComponents.queryItems?.first(where: { $0.name == "year" })?.value)!)
        let onDate = Calendar(identifier: .gregorian).date(from: components)!
        
        if let jsonString = String(data: data.0, encoding: .utf8) {
            do {
                let jsonData = jsonString.data(using: .utf8)!
                let res = try JSONDecoder().decode(ApiResponse.self, from: jsonData)
                response = FetchedResponse(onDate: onDate, response: res)
            } catch {
                print("[NativeDash]: Error while decoding JSON. \(error)")
                return
            }
        }
        guard let response = response else {
            return
        }
        
        context.perform {
            if storesDayType {
                do {
                    // Get current data from Core Data to manage it
                    let storedDayTypes = try context.fetch(StoredDayType.fetchRequest())
                    
                    
                    // Delete previous local stores
                    storedDayTypes.forEach(context.delete)
                    
                    // Store new schedules that have been fetched
                    for schedule in response.response.dayTypes {
                        _ = schedule.toStoredDayType(context: context)
                    }
                    
                    try context.save()
                    
                } catch {
                    print("[NativeDash]: failed to update StoredDayTypes. \(error)")
                    context.rollback()
                    return
                }
            }
            
            //         Insert next week's schedules into stores
            do {
                let storedScheduleOnDates = try context.fetch(StoredScheduleOnDate.fetchRequest())
                let storedDayTypes = try context.fetch(StoredDayType.fetchRequest())
                
                // Delete stores for past dates
                storedScheduleOnDates.filter({schedule in
                    return schedule.date!.timeIntervalSinceNow < 0 && !Calendar.current.isDateInToday(schedule.date!)
                }).forEach(context.delete)
                
                
                // Delete old store for looped date
                if let oldStore = storedScheduleOnDates.first(where: {Calendar.current.isDate($0.date!, inSameDayAs: response.onDate)}) {
                    context.delete(oldStore)
                }
                
                // Insert schedule into Core Data
                let storedSchedule = StoredScheduleOnDate(context: context)
                storedSchedule.date = response.onDate
                let possibleSchedule = storedDayTypes.first(where: {$0.name == response.response.dayTypeOnDate.name})
                storedSchedule.schedule = possibleSchedule ?? storedDayTypes.first
                
                try context.save()
            } catch {
                print("[NativeDash]: failed to update StoredScheduleOnDate. \(error)")
                context.rollback()
                return
            }
            print("Updated using background")
        }
    }
    
}
