//
//  PeriodTimerRing.swift
//  NativeDash
//
//  Created by Dalton Harrold on 10/29/23.
//

import SwiftUI
import Foundation


struct PeriodTimerRing: View {
    @Environment(\.scenePhase) var scenePhase
    
    var todaySchedule: DayType
    
    @State var progress: CGFloat
    @State var progrssInterval: CGFloat
    @State var timeLeftInPeriod: Duration
    @State var displayPeriod: Period?
    
    // Start a timer that fires an event every second to change the period time
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(todaySchedule: DayType) {
        self.todaySchedule = todaySchedule
        
        let currentDisplayPeriod = getNextPeriod(schedule: todaySchedule)
        self.displayPeriod = currentDisplayPeriod
        
        let secondsToEnd = getSecondsToPeriodStartEnd(period: currentDisplayPeriod, isEnd: true)
        self.timeLeftInPeriod = .seconds(secondsToEnd)
        
        let secondsToStart = getSecondsToPeriodStartEnd(period: currentDisplayPeriod, isEnd: false)
        
        let secondsInPeriod = secondsToEnd + secondsToStart
        
        self.progress = CGFloat(secondsToStart) / CGFloat(secondsInPeriod)
        self.progrssInterval = 1.0 / CGFloat(secondsInPeriod)
    }

    
    
     
    var body: some View {
        if displayPeriod != nil {
            #if os(iOS)
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
            Text(displayPeriod!.name)
                .font(.title)
                .fontWeight(.bold)
            Spacer().frame(height: 50)
            
            #elseif os(watchOS)
            
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color("EmptyAccentColor"), style: StrokeStyle(lineWidth: 20))
                        .frame(maxWidth: .infinity)
//                        .background(.orange)
                    Circle()
                        .rotation(Angle(degrees:(-(360*progress)-90)))
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color("AccentColor"),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
//                        .background(.purple)
                    Text(timeLeftInPeriod.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 0))))
                        .fontWeight(.semibold)
                        .font(.title)
//                        .background(.tertiary)
                }
                .padding(20)
                
                
                Text(displayPeriod!.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
//                    .background(.green)
            }
            .ignoresSafeArea(.container)
            
            
            #endif
        }
        
        EmptyView()
            // If the user re-enters the app after soft exiting it, update the display period
            .onChange(of: scenePhase, perform: { newPhase in
                if newPhase == .active {
                    changeDisplayPeriod()
                }
            })
            // Recieve the timer event and re-render affected elements
            .onReceive(timer, perform: { [self] time in
            
                // if at end of period, change what period is displaying
                // update progress by progress interval and lower seconds by 1
            
                if timeLeftInPeriod.components.seconds <= 0 {
                    changeDisplayPeriod()
                }
                progress += progrssInterval
                timeLeftInPeriod -= .seconds(1)
//            updateDisplayPeriodAndProgress()
//            if let nextPeriod = getNextPeriod(schedule: todaySchedule) {
//                periodRingShouldDisplay = true
//                timeLeftInPeriod = Duration.seconds(getSecondsToPeriodStartEnd(period: nextPeriod, isEnd: true))
//            } else {
//                // If no period is found, do not display the ring
//                periodRingShouldDisplay = false
//            }
            })
    }
    
    func changeDisplayPeriod() {
        displayPeriod = getNextPeriod(schedule: todaySchedule)
        let secondsToEnd = getSecondsToPeriodStartEnd(period: displayPeriod, isEnd: true)
        timeLeftInPeriod = .seconds(secondsToEnd)
        let secondsToStart = getSecondsToPeriodStartEnd(period: displayPeriod, isEnd: false)
        let secondsInPeriod = secondsToEnd + secondsToStart
        progress = CGFloat(secondsToStart) / CGFloat(secondsInPeriod)
        progrssInterval = 1.0 / CGFloat(secondsInPeriod)
    }

    
    
}

#Preview {
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
    return PeriodTimerRing(todaySchedule: todaySchedule)
}
