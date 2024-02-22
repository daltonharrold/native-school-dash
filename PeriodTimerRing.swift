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
    @State var displayPeriod: Period?

    
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
        Text(displayPeriod?.name ?? "")
                .font(.title)
                .fontWeight(.bold)
            Spacer().frame(height: 50)

        // Recieve the timer event and re-render affected elements
        .onReceive(timer, perform: { time in
            updateDisplayPeriodAndProgress()
            if let nextPeriod = getNextPeriod(schedule: todaySchedule) {
                timeLeftInPeriod = Duration.seconds(getSecondsToPeriodStartEnd(period: nextPeriod, isEnd: true))
            } else {
                // If no period is found, do not display the ring
                periodRingShouldDisplay = false
            }

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
