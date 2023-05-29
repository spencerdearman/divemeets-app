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
    @ObservedObject private var mpp: MeetPageParser = MeetPageParser()
    private let getTextModel = GetTextAsyncModel()
    var meetLink: String
    
    var body: some View {
        ZStack {
            if meetData != nil {
                ForEach((meetData ?? [:]).sorted(by: >), id: \.key) { key, value in
                    Text(key + ": " + value)
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
                }
            }
        }
    }
}
