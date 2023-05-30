//
//  MeetPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//  Revised for Meet Info/Results page on 5/28/23.
//

import SwiftUI
import SwiftSoup



struct MeetPageView: View {
    @State private var meetData: MeetPageData?
    @State private var meetEventData: MeetEventData?
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
    
    var body: some View {
        ZStack {
            VStack {
                ForEach(tupleToList(data: meetEventData ?? []), id: \.self) { elem in
                    Text("Date: " + elem[0])
                    Text("Event: " + elem[1])
                    Text("Name: " + elem[2])
                    Text("Rule: " + elem[3])
                    Text("Entries: " + elem[4])
                }
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
                    }
                }
            }
        }
    }
}
