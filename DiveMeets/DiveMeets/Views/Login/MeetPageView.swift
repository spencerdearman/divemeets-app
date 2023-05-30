//
//  MeetPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//  Revised for Meet Info/Results page on 5/28/23.
//

import SwiftUI

struct MeetPageView: View {
    @State private var meetData: MeetPageData?
    @State private var meetEventData: MeetEventData?
    @State private var meetDiverData: MeetDiverData?
    @State private var meetCoachData: MeetCoachData?
    @ObservedObject private var mpp: MeetPageParser = MeetPageParser()
    private let getTextModel = GetTextAsyncModel()
    var meetLink: String
    
    private func tupleToList(data: MeetEventData) -> [[String]] {
        var result: [[String]] = []
        for event in data {
            let date = event.0
            let number = String(event.1)
            let name = event.2
            let rule = event.3
            let entries = String(event.4)
            result.append([date, number, name, rule, entries])
        }
        
        return result
    }
    
    private func tupleToList(data: MeetDiverData) -> [[String]] {
        var result: [[String]] = []
        for diver in data {
            let name = diver.0
            let team = diver.1
            let link = diver.2
            
            var row = [name, team, link]
            for d in diver.3 {
                row.append(d)
            }
            
            result.append(row)
        }
        
        return result
    }
    
    private func tupleToList(data: MeetCoachData) -> [[String]] {
        var result: [[String]] = []
        
        for coach in data {
            result.append([coach.0, coach.1, coach.2])
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            VStack {
//                ForEach(tupleToList(data: meetEventData ?? []), id: \.self) { elem in
//                    Text("Date: " + elem[0])
//                    Text("Event: " + elem[1])
//                    Text("Name: " + elem[2])
//                    Text("Rule: " + elem[3])
//                    Text("Entries: " + elem[4])
//                }
                
//                ForEach(tupleToList(data: meetDiverData ?? []), id: \.self) { elem in
//                    Text("Name: " + elem[0])
//                    Text("Team: " + elem[1])
//                    Text("Link: " + elem[2])
//                }
                
                ForEach(tupleToList(data: meetCoachData ?? []), id: \.self) { elem in
                    Text("Name: " + elem[0])
                    Text("Team: " + elem[1])
                    Text("Link: " + elem[2])
                }
                
//                ForEach(tupleToList(data: meetResultsEventData ?? []), id: \.self) { elem in
//                    Text("Name: " + elem[0])
//                    Text("Link: " + elem[1])
//                    Text("Entries: " + elem[2])
//                    Text("Date: " + elem[3])
//                }
            }
        }
        .onAppear {
            Task {
                // Initialize meet parse from index page
                let url = URL(string: meetLink)!
                
                // This sets getTextModel's text field equal to the HTML from url
                await getTextModel.fetchText(url: url)
                
                if let html = getTextModel.text {
                    meetData = try await mpp.parseMeetPage(link: meetLink, html: html)
                    if meetData != nil {
                        meetEventData = await mpp.getEventData(data: meetData!)
                        meetDiverData = mpp.getDiverListData(data: meetData!)
                        meetCoachData = mpp.getCoachListData(data: meetData!)
                    }
                }
            }
        }
    }
}
