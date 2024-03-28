//
//  SingleCard.swift
//  NativeDash
//
//  Created by Dalton Harrold on 10/27/23.
//

import SwiftUI


struct SingleCard: View {
    var schedule: DayType
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("AccentColor"))
            VStack {
                Text(schedule.name)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .multilineTextAlignment(.center)
                Spacer().frame(height: 15)
                Grid(
                    alignment: .leading,
                    horizontalSpacing: 10.0,
                    verticalSpacing: 10.0
                ) {
                    ForEach(schedule.periods, id: \.name) { period in
                        GridRow {
                            Text(period.name)
                                .multilineTextAlignment(.trailing)
                                .gridColumnAlignment(.trailing)
                            Spacer().frame(width: 15, height: 1)
                            Text("\(period.startInLocale) - \(period.endInLocale)")
                                .gridColumnAlignment(.leading)
                        }
                    }
                }
                .truncationMode(/*@START_MENU_TOKEN@*/.head/*@END_MENU_TOKEN@*/)
                .font(.body)
            }
            .padding(30)
            .fontWeight(.bold)
            .foregroundStyle(.white)
        }
        .fixedSize(horizontal: false, vertical: true)
        
        
    }
}

#Preview {
    var previewSchedule: DayType =
        DayType(
            name: "Regular Schedule",
            periods: [
                .init(name: "Assembly", start: "8:30", end: "8:45"),
                .init(name: "Period 1", start: "8:49", end: "9:32"),
                .init(name: "Period 2", start: "9:35", end: "10:17"),
                .init(name: "Period 3", start: "10:21", end: "11:03"),
            ]
        )
    
    
    return SingleCard(schedule: previewSchedule)
}
