//
//  Event.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/5/23.
//

import SwiftUI

struct Event: View {
    @Binding var meet: MeetEvent
    @State var diverData : (String, String, String, Double, Double, Double) = ("", "", "", 0.0, 0.0, 0.0)
    @State var diverTableData: [Int: (String, String, String, Double, Double, Double, String)] = [:]
    
    @StateObject private var parser = EventHTMLParser()
    
    var body: some View {
        ZStack{}
            .onAppear {
                Task {
                    await parser.eventParse(urlString: meet.link!)
                    diverData = parser.eventData
                    print(diverData)
                    await parser.tableDataParse(urlString: meet.link!)
                    diverTableData = parser.diveTableData
                }
            }
        VStack{
            Spacer()
            Text(meet.name)
                .font(.headline)
            Spacer()
            Text(meet.link!)
        }
        .padding()
    }
}

