//
//  EntryPageView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 6/2/23.
//

import SwiftUI

struct EntryPageView: View {
    @State var entries: [EventEntry]?
    @ObservedObject var ep: EntriesParser = EntriesParser()
    private let getTextModel = GetTextAsyncModel()
    
    var body: some View {
        ZStack {
            if entries != nil {
                ScrollView(showsIndicators: false) {
                    VStack {
                        ForEach(entries!, id: \.self) { entry in
                            EntryView(entry: entry)
                                .padding()
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                let link = "https://secure.meetcontrol.com/divemeets/system/divesheetext.php?meetnum=9032&eventnum=450&eventtype=9"
                // Initialize meet parse from index page
                let url = URL(string: link)!
                
                // This sets getTextModel's text field equal to the HTML from url
                await getTextModel.fetchText(url: url)
                
                if let html = getTextModel.text {
                    entries = try await ep.parseEntries(html: html)!
                }
                
            }
        }
    }
}

struct EntryView: View {
    var entry: EventEntry
    
    var body: some View {
        HStack(alignment: .top) {
            Text((entry.lastName ?? "") + ", " + (entry.firstName ?? ""))
            VStack {
                ForEach(entry.dives ?? [], id: \.self) { dive in
                    Text(dive.number)
                }
            }
            Text(String(entry.totalDD ?? 0.0))
            Text(entry.board ?? "")
        }
    }
}

struct EntryPageView_Previews: PreviewProvider {
    static var previews: some View {
        EntryPageView()
    }
}
