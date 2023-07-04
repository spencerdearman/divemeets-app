//
//  ProfileView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI
import SwiftSoup

struct ProfileView: View {
    @Environment(\.colorScheme) var currentMode
    
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
    @State private var diversAndLinks: [[String]] = []
    @State private var judgingHistory: [String: [(String, String)]] = [:]
    private let getTextModel = GetTextAsyncModel()
    private let ep = EntriesParser()
    
    var diverID: String {
        String(profileLink.suffix(5))
    }
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
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
    
    private func getNameComponents() -> [String]? {
        // Case where only State label is provided
        var comps = diverData[0][0].slice(from: "Name: ", to: " State:")
        if comps == nil {
            // Case where City/State label is provided
            comps = diverData[0][0].slice(from: "Name: ", to: " City/State:")
            
            if comps == nil {
                // Case where no labels are provided (shell profile)
                comps = diverData[0][0].slice(from: "Name: ", to: " DiveMeets ID:")
            }
        }
        
        guard let comps = comps else { return nil }
        
        return comps.components(separatedBy: " ")
    }
    
    private func isDictionary(_ object: Any) -> Bool {
        let mirror = Mirror(reflecting: object)
        return mirror.displayStyle == .dictionary
    }
    
    var body: some View {
        
        ZStack {
            bgColor.ignoresSafeArea()
            
            if profileType == "Diver" {
                VStack {
                    ProfileImage(diverID: diverID)
                        .frame(width: 200, height: 150)
                        .padding()
                    VStack {
                        VStack(alignment: .leading) {
                            HStack (alignment: .firstTextBaseline) {
                                let nameComps = getNameComponents()
                                
                                let firstName = nameComps?.dropLast().joined(separator: " ") ?? ""
                                let lastName = nameComps?.last ?? ""
                                
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
                    
                    Spacer()
                    
                    
                    MeetList(profileLink: profileLink)
                    
                }
                .padding(.bottom, maxHeightOffset)
            } else {
                VStack {
                    VStack {
                        ProfileImage(diverID: diverID)
                            .frame(width: 200, height: 120)
                            .padding()
                            .padding(.bottom)
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
                        }
                        .padding()
                        ScrollView{
                            Text("Divers")
                                .font(.title2).fontWeight(.semibold)
//                            DiversList(diversAndLinks: $diversAndLinks)
//                                .offset(y: -45)
                            JudgedList(data: $judgingHistory)
                                .offset(y: -50)
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await fetchJudgingData()
            }
        }
    }
    
    func fetchJudgingData() async {
        do {
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
                let document: Document = try SwiftSoup.parse(text)
                guard let body = document.body() else { return }
                let td = try body.getElementsByTag("td")
                let divers = try body.getElementsByTag("a")
                for (i, diver) in divers.enumerated(){
                    if try diver.text() == "Coach Profile"{
                        continue
                    } else if try diver.text() == "Results" {
                        break
                    } else {
                        let link = try "https://secure.meetcontrol.com/divemeets/system/"
                        + diver.attr("href")
                        diversAndLinks.append([try diver.text(), link])
                    }
                }
                
                var current = ""
                var eventsList: [(String, String)] = []
                let judgingHistoryTable = try td[0].getElementsByTag("table")
                if !judgingHistoryTable.isEmpty {
                    let tr = try judgingHistoryTable[0].getElementsByTag("tr")
                    for (i, t) in tr.enumerated() {
                        if i == 0 {
                            continue
                        } else if try t.text().contains("Results") {
                            let event = try t.getElementsByTag("td")[0].text()
                                .replacingOccurrences(of: "  ", with: "")
                            let resultsLink = try "https://secure.meetcontrol.com/divemeets/system/"
                            + t.getElementsByTag("a").attr("href")
                            eventsList.append((event, resultsLink))
                        } else {
                            if i > 1 {
                                judgingHistory[current] = eventsList
                                eventsList = []
                                current = try t.text()
                            } else {
                                current = try t.text()
                            }
                        }
                    }
                    if !current.isEmpty {
                        judgingHistory[current] = eventsList
                    }
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
}

struct DiversList: View {
    @Binding var diversAndLinks: [[String]]
    
    var body: some View {
        VStack (spacing: 1){
            TabView {
                ForEach(diversAndLinks, id: \.self) { elem in
                    DiverBubbleView(elements: elem)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .frame(height: 285)
        }
    }
}

struct DiverBubbleView: View {
    @Environment(\.colorScheme) var currentMode
    @State private var focusBool: Bool = false
    
    private var bubbleColor: Color {
        currentMode == .light ? .white : .black
    }
    private var elements: [String]
    
    init(elements: [String]) {
        self.elements = elements
    }
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(bubbleColor)
                .cornerRadius(30)
                .frame(width: 400, height: 200)
                .shadow(radius: 5)
            NavigationLink {
                ProfileView(profileLink: elements[1])
            } label: {
                Text(elements[0])
                    .fontWeight(.semibold)
            }
            
        }
    }
}

struct JudgedList: View {
    @Binding var data: [String: [(String, String)]]
    
    var body: some View {
        Text("Judging History")
            .font(.title2).fontWeight(.semibold)
        List {
            ForEach(data.keys.sorted(by: >), id: \.self) { dropdownKey in
                DisclosureGroup(
                    content: {
                        ForEach(data[dropdownKey] ?? [], id: \.0) { tuple in
                            NavigationLink {
                                EventResultPage(meetLink: tuple.1)
                            } label: {
                                Text(tuple.0)
                            }
                        }
                    },
                    label: {
                        Text(dropdownKey)
                    }
                )
            }
        }
    }
}
