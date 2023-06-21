//
//  ProfileView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct ProfileView: View {
    var profileLink: String
    @State var diverData : [[String]] = []
    @State var profileType : String = ""
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    @StateObject private var parser = HTMLParser()
    @State private var isExpanded: Bool = false
    //                                          [meetName: [eventName: entriesLink]
    @State private var upcomingDiveSheetsLinks: [String: [String: String]]?
    @State private var upcomingDiveSheetsEntries: [String: [String: EventEntry]]?
    private let getTextModel = GetTextAsyncModel()
    private let ep = EntriesParser()
    
    var diverID: String {
        String(profileLink.suffix(5))
    }
    
    private func getUpcomingDiveSheetsEntries(name: String) async -> [String: [String: EventEntry]]? {
        var result: [String: [String: EventEntry]] = [:]
        guard let sheetsLinks = upcomingDiveSheetsLinks else { return nil }
        
        for (meetName, meetDict) in sheetsLinks {
            result[meetName] = [:]
            for (eventName, sheetLink) in meetDict {
                // Initialize meet parse from index page
                guard let url = URL(string: sheetLink) else { return nil }
                
                // This sets getTextModel's text field equal to the HTML from url
                await getTextModel.fetchText(url: url)
                
                do {
                    if let html = getTextModel.text,
                       let entry = try ep.parseNamedEntry(html: html, searchName: name) {
                        result[meetName]![eventName] = entry
                    }
                } catch {
                    print("Parsing named entry failed")
                }
            }
        }
        
        return result
    }
    
    var body: some View {
        
        ZStack{}
            .onAppear {
                Task {
                    await parser.parse(urlString: profileLink)
                    diverData = parser.myData
                     let divers = diverData[0][0].slice(from: "Divers:", to: "Judging") ?? ""
                    
                    if divers != "" {
                        profileType = "Coach"
                    } else {
                        profileType = "Diver"
                    }
                    
                    guard let url = URL(string: profileLink) else { return }
                    await getTextModel.fetchText(url: url)
                    if let text = getTextModel.text {
                        upcomingDiveSheetsLinks = try await ep.parseProfileUpcomingMeets(html: text)
                        let nameText = diverData[0][0].slice(from: "Name: ", to: " State:")
                        let comps = nameText?.split(separator: " ")
                        let last = String(comps?.last ?? "")
                        let first = String(comps?.dropLast().joined(separator: " ") ?? "")
                        
                        if upcomingDiveSheetsLinks != nil {
                            upcomingDiveSheetsEntries = await getUpcomingDiveSheetsEntries(name: last + ", " + first)
                        }
                        
                    }
                }
            }
        
        if profileType == "Diver" {
            VStack {
                VStack {
                    ProfileImage(diverID: diverID)
                        .frame(width: 200, height: 150)
                        .padding()
                    VStack {
                        VStack(alignment: .leading) {
                            HStack (alignment: .firstTextBaseline) {
                                let firstName = diverData[0][0].slice(from: "Name: ", to: " ") ?? ""
                                let lastName =
                                diverData[0][0].slice(from: firstName + " ", to: " ") ?? ""
                                
                                diverData != []
                                ? Text(firstName + " " + lastName) .font(.title)
                                : Text("")
                                
                                Text(diverID)
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                            Divider()
                            HStack (alignment: .firstTextBaseline) {
                                Image(systemName: "house.fill")
                                diverData != []
                                ? Text(
                                    (diverData[0][0].slice(from: "State: ", to: " Country")  ?? "")
                                    + ", "
                                    + (diverData[0][0].slice(from: " Country: ",
                                                             to: " Gender") ?? ""))
                                : Text("")
                            }
                            .font(.subheadline)
                            HStack (alignment: .firstTextBaseline) {
                                Image(systemName: "person.circle")
                                diverData != []
                                ? Text("Gender: " +
                                       (diverData[0][0].slice(from: " Gender: ", to: " Age") ?? ""))
                                : Text("")
                                diverData != []
                                ? Text("Age: " +
                                       (diverData[0][0].slice(from: " Age: ", to: " FINA") ?? ""))
                                : Text("")
                                diverData != []
                                ? Text("FINA Age: " +
                                       (diverData[0][0].slice(from: " FINA Age: ",
                                                              to: " High") ?? ""))
                                : Text("")
                            }
                            .font(.subheadline)
                            .padding([.leading], 2)
                            Divider()
                        }
                    }
                    .padding([.leading, .trailing, .top])
                    
                    if let upcomingDiveSheetsEntries = upcomingDiveSheetsEntries {
                        DisclosureGroup(isExpanded: $isExpanded) {
                            ForEach(upcomingDiveSheetsEntries.sorted(by: { $0.key < $1.key }),
                                    id: \.key) { meetName, events in
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(meetName)
                                        .font(.title3)
                                        .bold()
                                    VStack(spacing: 5) {
                                        ForEach(events.sorted(by: { $0.key < $1.key }),
                                                id: \.key) { eventName, entry in
                                            EntryView(entry: entry) {
                                                Text(eventName)
                                                    .font(.headline)
                                                    .bold()
                                                    .foregroundColor(Color.primary)
                                            }
                                        }
                                    }
                                    .padding(.leading)
                                    .padding(.top, 5)
                                }
                                .padding(.top, 5)
                            }
                        } label: {
                            Text("Upcoming Meets")
                                .font(.title2)
                                .bold()
                                .foregroundColor(Color.primary)
                        }
                        .padding([.leading, .trailing])
                        .padding(.bottom, 5)
                    }
                }
                Text("Meets")
                    .font(.title2)
                    .padding(.bottom)
                MeetList(profileLink: profileLink)
                Spacer()
            }
            .padding(.bottom, maxHeightOffset)
        } else {
            VStack {
                VStack {
                    Spacer()
                    ProfileImage(diverID: diverID)
                        .offset(y:-100)
                    VStack{
                        VStack(alignment: .leading) {
                            HStack (alignment: .firstTextBaseline){
                                diverData != []
                                ? Text(diverData[0][0].slice(from: "Name: ",
                                                             to: " City/State") ?? "").font(.title)
                                : Text("")
                                
                                Text(diverID)
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                            Divider()
                            HStack (alignment: .firstTextBaseline){
                                Image(systemName: "house.fill")
                                diverData != []
                                ? Text(
                                    (diverData[0][0].slice(from: " City/State: ",
                                                           to: " Country")  ?? "")
                                    + ", "
                                    + (diverData[0][0].slice(from: " Country: ",
                                                             to: " Gender") ?? "")): Text("")
                            }
                            .font(.subheadline)
                            HStack (alignment: .firstTextBaseline) {
                                Image(systemName: "person.circle")
                                diverData != []
                                ? Text("Gender: " + (diverData[0][0].slice(from: " Gender: ",
                                                                           to: " DiveMeets") ?? ""))
                                : Text("")
                            }
                            .font(.subheadline)
                            .padding([.leading], 2)
                            Divider()
                        }
                        .offset(y:-150)
                    }
                    .padding()
                }
            }
        }
    }
}
