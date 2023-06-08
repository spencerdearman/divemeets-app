//
//  EntryPageView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 6/2/23.
//

import SwiftUI

struct EntryPageView: View {
    @Environment(\.colorScheme) var currentMode
    @State var entries: [EventEntry]?
    @ObservedObject var ep: EntriesParser = EntriesParser()
    private let getTextModel = GetTextAsyncModel()
    private var grayColor: Color {
        currentMode == .light ? Color(red: 0.9, green: 0.9, blue: 0.9) : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    var body: some View {
        ZStack {
            grayColor
            if entries != nil {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(entries!, id: \.self) { entry in
                            ZStack {
                                Rectangle()
                                    .fill(.white)
                                    .cornerRadius(15)
                                EntryView(entry: entry)
                                    .padding()
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                let link = "https://secure.meetcontrol.com/divemeets/system/divesheetext.php?meetnum=9032&eventnum=1030&eventtype=9"
                // Initialize meet parse from index page
                let url = URL(string: link)!
                
                // This sets getTextModel's text field equal to the HTML from url
                await getTextModel.fetchText(url: url)
                
                if let html = getTextModel.text {
                    entries = try await ep.parseEntries(html: html)
                }
                
            }
        }
    }
}

struct EntryView: View {
    var entry: EventEntry
    @State var isExpanded: Bool = false
    
    private func getHeaderString(_ entry: EventEntry) -> String {
        let last = entry.lastName ?? ""
        let first = entry.firstName ?? ""
        let team = entry.team ?? ""
        return last + ", " + first + " (" + team + ")"
    }
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                HStack {
                    VStack {
                        ForEach(entry.dives ?? [], id: \.self) { dive in
                            Text(dive.number)
                        }
                    }
                    Text(String(entry.totalDD ?? 0.0))
                    Text(entry.board ?? "")
                }
            },
            label: {
                Text(getHeaderString(entry))
                    .font(.headline)
                    .foregroundColor(Color.primary)
            }
        )
    }
}

struct EntryPageView_Previews: PreviewProvider {
    static var previews: some View {
        EntryPageView()
    }
}
