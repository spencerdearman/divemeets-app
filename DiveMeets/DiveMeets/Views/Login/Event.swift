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
    @State var scoreData : [Int: Double] = [:]
    
    @StateObject private var parser = EventHTMLParser()
    @StateObject private var scoreParser = ScoreHTMLParser()
    
    var body: some View {
        ZStack{}
            .onAppear {
                Task {
                    await parser.eventParse(urlString: meet.link!)
                    diverData = parser.eventData
                    await parser.tableDataParse(urlString: meet.link!)
                    diverTableData = parser.diveTableData
                    //print(diverTableData)
                    await scoreParser.parse(urlString: "https://secure.meetcontrol.com/divemeets/system/judgesscoresext.php?meetnum=8698&eventnum=7180&dvrnum=51197&divord=1&eventtype=9&synchdvrnum=&sts=1674154171")
                    scoreData = scoreParser.scoreData
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

