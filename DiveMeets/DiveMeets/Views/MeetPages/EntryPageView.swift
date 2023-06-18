//
//  EntryPageView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 6/2/23.
//

import SwiftUI

struct EntryPageView: View {
    @Environment(\.colorScheme) var currentMode
    var entriesLink: String
    @State var entries: [EventEntry]?
    @ObservedObject var ep: EntriesParser = EntriesParser()
    private let getTextModel = GetTextAsyncModel()
    private var grayColor: Color {
        currentMode == .light
        ? Color(red: 0.9, green: 0.9, blue: 0.9)
        : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    var body: some View {
        ZStack {
            if let entries = entries {
                grayColor
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(entries, id: \.self) { entry in
                            ZStack {
                                Rectangle()
                                    .fill(currentMode == .light ? .white : .black)
                                    .cornerRadius(15)
                                EntryView(entry: entry)
                                    .padding()
                            }
                        }
                    }
                    .padding(10)
                }
            } else {
                VStack {
                    Text("No entries found for this event")
                    Text("(This event may have already started)")
                }
            }
        }
        .onAppear {
            Task {
                // Initialize meet parse from index page
                let url = URL(string: entriesLink)
                
                if let url = url {
                    // This sets getTextModel's text field equal to the HTML from url
                    await getTextModel.fetchText(url: url)
                    
                    if let html = getTextModel.text {
                        entries = try await ep.parseEntries(html: html)
                    }
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
                VStack(alignment: .leading) {
                    Text(entry.board != nil ? "Board: " + entry.board! : "")
                    HStack(alignment: .top) {
                        VStack {
                            Text("Number")
                                .bold()
                            ForEach(entry.dives ?? [], id: \.self) { dive in
                                Text(dive.number)
                            }
                        }
                        Spacer()
                        VStack {
                            Text("Height")
                                .bold()
                            ForEach(entry.dives ?? [], id: \.self) { dive in
                                Text(String(dive.height) + "M")
                            }
                        }
                        Spacer()
                        VStack {
                            Text("Name")
                                .bold()
                            ForEach(entry.dives ?? [], id: \.self) { dive in
                                Text(dive.name)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        VStack {
                            Text("DD")
                                .bold()
                            ForEach(entry.dives ?? [], id: \.self) { dive in
                                Text(String(dive.dd))
                            }
                        }
                    }
                }
                .scaledToFit()
                .minimumScaleFactor(0.1)
            },
            label: {
                Text(getHeaderString(entry))
                    .font(.headline)
                    .foregroundColor(Color.primary)
                    .scaledToFit()
                    .minimumScaleFactor(0.1)
                    .lineLimit(1)
            }
        )
    }
}
