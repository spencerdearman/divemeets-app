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
    @Namespace var profilespace
    @State var diverData : [[String]] = []
    @State var profileType : String = ""
    @State var diverTab: Bool = false
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
                ZStack{
                    GeometryReader{ geometry in
                        BackgroundSpheres()
                        Rectangle()
                            .fill(Custom.background)
                            .mask(RoundedRectangle(cornerRadius: 40))
                            .offset(y: geometry.size.height * 0.4)
                    }
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
                                    ? Text(firstName + " " + lastName) .font(.title).foregroundColor(.white)
                                    : Text("")
                                    
                                    Text(diverID)
                                        .font(.subheadline).foregroundColor(Custom.secondaryColor)
                                }
                                WhiteDivider()
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
                                .font(.subheadline).foregroundColor(.white)
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
                                .font(.subheadline).foregroundColor(.white)
                                .padding([.leading], 2)
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
                }
            } else {
                ZStack{
                    GeometryReader{ geometry in
                        BackgroundSpheres()
                        Rectangle()
                            .fill(Custom.background)
                            .mask(RoundedRectangle(cornerRadius: 40))
                            .offset(y: geometry.size.height * 0.4)
                    }
                    VStack {
                        VStack {
                            ProfileImage(diverID: diverID)
                                .frame(width: 200, height: 150)
                                .padding()
                            VStack{
                                VStack(alignment: .leading) {
                                    HStack (alignment: .firstTextBaseline){
                                        diverData != []
                                        ? Text(diverData[0][0].slice(from: "Name: ",
                                                                     to: " City/State") ?? "").font(.title).foregroundColor(.white)
                                        : Text("")
                                        
                                        Text(diverID)
                                            .font(.subheadline).foregroundColor(Custom.secondaryColor)
                                    }
                                    WhiteDivider()
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
                                    .font(.subheadline).foregroundColor(.white)
                                    HStack (alignment: .firstTextBaseline) {
                                        Image(systemName: "person.circle")
                                        diverData != []
                                        ? Text("Gender: " + (diverData[0][0].slice(from: " Gender: ",
                                                                                   to: " DiveMeets") ?? ""))
                                        : Text("")
                                    }
                                    .font(.subheadline).foregroundColor(.white)
                                    .padding([.leading], 2)
                                }
                            }
                            .padding()
                            if !diverTab{
                                VStack{
                                    Spacer()
                                }
                                .frame(width: 100, height: 50)
                                .foregroundStyle(.white)
                                .background(
                                    Custom.carouselColor.matchedGeometryEffect(id: "background", in: profilespace)
                                )
                                .mask(
                                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                                        .matchedGeometryEffect(id: "mask", in: profilespace)
                                )
                                .shadow(radius: 5)
                                .overlay(
                                    ZStack{
                                        Text("Divers")
                                            .font(.title3).fontWeight(.semibold)
                                            .matchedGeometryEffect(id: "title", in: profilespace)
                                    })
                                .padding(.top, 8)
                                .onTapGesture{
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        diverTab.toggle()
                                    }
                                }
                            } else {
                                ZStack{
                                    VStack{
                                        Text("Divers")
                                            .padding(.top)
                                            .font(.title3).fontWeight(.semibold)
                                            .matchedGeometryEffect(id: "title", in: profilespace)
                                            .onTapGesture{
                                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                    diverTab.toggle()
                                                }
                                            }
                                        DiversList(diversAndLinks: $diversAndLinks)
                                            .offset(y: -20)
                                    }
                                    .padding(.top, 8)
                                }
                                .background(
                                    Custom.carouselColor.matchedGeometryEffect(id: "background", in: profilespace)
                                )
                                .mask(
                                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                                        .matchedGeometryEffect(id: "mask", in: profilespace)
                                )
                                .shadow(radius: 10)
                                .frame(width: 375, height: 300)
                            }
                            JudgedList(data: $judgingHistory)
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
                print(diversAndLinks)
                
                
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
            .frame(height: 190)
        }
    }
}

struct DiverBubbleView: View {
    @Environment(\.colorScheme) var currentMode
    @State private var focusBool: Bool = false
    private let getTextModel = GetTextAsyncModel()
    
    private var elements: [String]
    
    init(elements: [String]) {
        self.elements = elements
    }
    
    var body: some View {
        var link = ""
        ZStack {
            Rectangle()
                .foregroundColor(Custom.thinMaterialColor)
                .cornerRadius(30)
                .frame(width: 300, height: 100)
                .shadow(radius: 5)
            HStack{
                NavigationLink {
                    ProfileView(profileLink: elements[1])
                } label: {
                    Text(elements[0])
                        .fontWeight(.semibold)
                }
                MiniProfileImage(diverID: String(elements[1].utf16.dropFirst(67)) ?? "", width: 80, height: 100)
                    .padding(.leading)
                    .scaledToFit()
            }
            
        }
    }
}

struct JudgedList: View {
    @Binding var data: [String: [(String, String)]]
    
    let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 10
    
    var body: some View {
        
        VStack {
            Text("Judging History")
                .font(.title2).fontWeight(.semibold)
                .padding(.top)
            ScrollView(showsIndicators: false) {
                VStack(spacing: rowSpacing) {
                    ForEach(data.keys.sorted(by: >), id: \.self) { dropdownKey in
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Custom.tileColor)
                                .shadow(radius: 5)
                            DisclosureGroup(
                                content: {
                                    VStack(spacing: 5) {
                                        ForEach(data[dropdownKey] ?? [], id: \.0) { tuple in
                                            let shape = RoundedRectangle(cornerRadius: 30)
                                            NavigationLink(destination:
                                                            EventResultPage(meetLink: tuple.1))
                                            {
                                                ZStack {
                                                    shape.fill(Custom.thinMaterialColor)
                                                    
                                                    HStack {
                                                        Text(tuple.0)
                                                        Spacer()
                                                        Image(systemName: "chevron.right")
                                                            .foregroundColor(.blue)
                                                    }
                                                    .frame(height: 80)
                                                    .padding()
                                                    
                                                }
                                                .foregroundColor(.primary)
                                                .padding([.leading, .trailing])
                                            }
                                        }
                                    }
                                    .padding(.bottom)
                                },
                                label: {
                                    Text(dropdownKey)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Custom.textColor)
                                        .padding()
                                }
                            )
                            .padding([.leading, .trailing])
                        }
                        .padding([.leading, .trailing])
                    }
                }
                .padding([.top, .bottom], rowSpacing)
            }
        }
    }
}

struct BackgroundSpheres: View {
    @State var width: CGFloat = 0
    @State var height: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack{}
                .onAppear{
                    width = geometry.size.width
                    height = geometry.size.height
                }
            VStack {
                ZStack{
                    Circle()
                        .fill(Custom.darkBlue) // Circle color
                        .frame(width: geometry.size.width
                               * 2.5, height: geometry.size.width * 2.5) // Adjust the size of the circle as desired
                        .position(x: geometry.size.width, y: -geometry.size.width * 0.55) // Center the circle
                        .shadow(radius: 15)
                    Circle()
                        .fill(Custom.coolBlue) // Circle color
                        .frame(width:geometry.size.width
                               * 1.3, height:geometry.size.width * 1.3)
                        .position(x: geometry.size.width * 0.8, y: geometry.size.width * 0.6)
                        .shadow(radius: 15)
                    Circle()
                        .fill(Custom.medBlue) // Circle color
                        .frame(width: geometry.size.width
                               * 1.1, height: geometry.size.width * 1.1)
                        .position(x: 0, y: geometry.size.width * 0.65)
                        .shadow(radius: 15)
                }
            }
        }
    }
}
