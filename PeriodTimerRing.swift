//
//  PeriodTimerRing.swift
//  NativeDash
//
//  Created by Dalton Harrold on 10/29/23.
//

import SwiftUI

struct PeriodTimerRing: View {
    @Binding var todaySchedule: DayType
    
    @State var progress: CGFloat = 0.0
    @State var timeLeftInPeriod: Duration = Duration.seconds(0)
    @State var periodRingShouldDisplay: Bool = false
    @State var displayPeriod: Period = Period(name: "Init period", start: "00:00", end: "00:00")

    
    // Start a timer that fires an event every second to change the period time
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
     
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("EmptyAccentColor"), style: StrokeStyle(lineWidth: 20))
            Circle()
                .rotation(Angle(degrees:(-(360*progress)-90)))
                .trim(from: 0, to: progress)
                .stroke(
                    Color("AccentColor"),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
            )
            Text(timeLeftInPeriod.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 0))))
                .fontWeight(.semibold)
                .font(.title)
        }
        .frame(idealWidth: 300, idealHeight: 300, alignment: .center) 
            Spacer().frame(height: 50)
            Text(displayPeriod.name)
                .font(.title)
                .fontWeight(.bold)
            Spacer().frame(height: 50)

        // Recieve the timer event and re-render affected elements
        .onReceive(timer, perform: { time in
            updateDisplayPeriodAndProgress()
            timeLeftInPeriod = Duration.seconds(getSecondsToPeriodStartEnd(period: getNextPeriod(schedule: todaySchedule), isEnd: true))

        })
    }
    
    func applicationWillEnterForeground() {
        timeLeftInPeriod -= .seconds(1)
        updateDisplayPeriodAndProgress()
    }
    
    func updateDisplayPeriodAndProgress() {
        // Change Progress value to reflect percentage of period elapsed
        displayPeriod = getNextPeriod(schedule: todaySchedule)
        let secondsToEnd = getSecondsToPeriodStartEnd(period: displayPeriod, isEnd: true)
        let secondsToStart = getSecondsToPeriodStartEnd(period: displayPeriod, isEnd: false)
        progress = CGFloat(secondsToStart) / CGFloat(secondsToEnd + secondsToStart)
    }
    
    // Get the number of seconds to the start or end of current period. Time must be between given period start or end
    // If isEnd = true, will return time to end, else will return time to start
    func getSecondsToPeriodStartEnd(period: Period, isEnd: Bool) -> Int {
        let nextPeriodEndTime = (isEnd ? period.end : period.start) + ":00"
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd ZZZZ"
        let yearMonthDay = formatter.string(from: date)
        formatter.dateFormat = "yyyy/MM/dd ZZZZ HH:mm:ss"
        let endOfPeriod = formatter.date(from: "\(yearMonthDay) \(nextPeriodEndTime)")
        let diff = abs(endOfPeriod!.timeIntervalSinceNow)
        return Int(diff)
    }
    
    func getNextPeriod(schedule: DayType) -> Period {
        var periodToReturn: Period?
        let date = Date()
        let formatter = DateFormatter()
        // We need to be able to make a date object setting the end of the period as the time, so we need to get the current date and re-input it in the date constructor
        formatter.dateFormat = "yyyy/MM/dd ZZZZ"
        let yearMonthDay = formatter.string(from: date)
        formatter.dateFormat = "yyyy/MM/dd ZZZZ HH:mm:ss"
        
        for (index, period) in schedule.periods.enumerated() {
            // If period start is in future (Currently in a passing period)
            let timeSincePeriodStart = formatter.date(from: "\(yearMonthDay) \(period.start):00")!.timeIntervalSinceNow
            let timeSincePeriodEnd = formatter.date(from: "\(yearMonthDay) \(period.end):00")!.timeIntervalSinceNow
            
            // If period start is in future (Currently in passing period)
            if timeSincePeriodStart > 0 {
                if index == 0 {
                    // If before school, do not display period ring
                    periodRingShouldDisplay = false
                    break
                }
                periodToReturn = Period(name: "\(schedule.periods[index-1].name) → \(period.name)", start: schedule.periods[index-1].end, end: period.start)
                periodRingShouldDisplay = true
                break
            } // If period end is in future (Currently in a period)
            else if timeSincePeriodEnd > 0 {
                periodToReturn = period
                periodRingShouldDisplay = true
                break
            }
            
            // If no period detected and loop is on last period in schedule, assume after-school hours
            // and do not display period ring timer
            if index+1 == schedule.periods.count {
                periodRingShouldDisplay = false
                break
            }
        }
        return periodToReturn ?? Period(name: "Period not found", start: "00:00", end: "00:00")
    }
}

#Preview {
    @State var progress: CGFloat = 0.8
    @State var timeLeftInPeriod: Duration = Duration.seconds(633)
    @State var todaySchedule = DayType(
        name: "Common Day",
        periods: [
            .init(name: "Assembly", start: "8:30", end: "8:37"),
            .init(name: "Period 1", start: "8:41", end: "9:20"),
            .init(name: "Period 2", start: "9:24", end: "10:03"),
            .init(name: "Period 3", start: "10:07", end: "10:46"),
            .init(name: "Common", start: "10:50", end: "11:17"),
            .init(name: "Period 4", start: "11:21", end: "12:01"),
            .init(name: "Period 5", start: "12:05", end: "12:45"),
            .init(name: "Period 6", start: "12:49", end: "13:29"),
            .init(name: "Period 7", start: "13:33", end: "14:13"),
            .init(name: "Period 8", start: "14:17", end: "14:57"),
            .init(name: "Period 9", start: "15:01", end: "15:41"),
            .init(name: "Period 10", start: "15:45", end: "16:25")
        ]
    )
    return PeriodTimerRing(todaySchedule: .constant(todaySchedule), progress: progress, timeLeftInPeriod: timeLeftInPeriod, periodRingShouldDisplay: true)
}
