//
//  DataStructs.swift
//  NativeDash
//
//  Created by Dalton Harrold on 11/1/23.
//

import Foundation
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
}

public struct Period: Decodable {
    var name: String
    var start: String
    var end: String
}

public struct apiResponse: Decodable {
    let dayTypeOnDate: DayType
    let name: String
    let _id: String
    let dayTypes: [DayType]
}

public func getFromApi() async throws -> apiResponse? {
    let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: Date())
    if let url = URL(string: "\(ProcessInfo.processInfo.environment["API_ENDPOINT"]!)/schools/\( ProcessInfo.processInfo.environment["SCHOOL_ID"]!)?includes=dayTypeOnDate&day=\(calendarDate.day!)&month=\(calendarDate.month!)&year=\(calendarDate.year!)") {
        var request = URLRequest(url: url)
        request.setValue(ProcessInfo.processInfo.environment["API_KEY"], forHTTPHeaderField: "authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            do {
                let jsonData = jsonString.data(using: .utf8)!
                let returnData = try JSONDecoder().decode(apiResponse.self, from: jsonData)
                return returnData
            } catch let error {
                print(error)
            }
        }
    }
    return nil
}
