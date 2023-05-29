//
//  EventResultPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/26/23.
//

import SwiftUI


struct EventResultPage: View {
    @StateObject private var parser = EventPageHTMLParser()
    @State var meetLink: String = "https://secure.meetcontrol.com/divemeets/system/eventresultsext.php?meetnum=7984&eventnum=1020&eventtype=9"
    @State var resultData: [Int: (String, String, String, String, Double, String, String)] = [:]
    
    var body: some View {
        ZStack{}
            .onAppear {
                Task {
                    await parser.parse(urlString: meetLink)
                    resultData = parser.eventPageData
                }
            }
        Text("Hello World")
    }
}
