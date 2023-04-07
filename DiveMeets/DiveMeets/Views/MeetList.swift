//
//  MeetList.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct MeetList: View {
    @Environment(\.colorScheme) var currentMode
    var profileLink: String
    @State var diverData: [Array<String>] = []
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    @Binding var hideTabBar: Bool
    @StateObject private var parser = HTMLParser()
    
    /// Style adjustments for elements of list
    private let frameWidth: CGFloat = 350
    private let frameHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 3
    private let fontSize: CGFloat = 20
    let startIndex = 2
    
    func createMeets(data: [[String]]) -> [Meet]? {
        if data.count < 2 {
            return nil
        }
        
        var meets = [Meet]()
        var currentMeetName = ""
        var currentMeetEvents = [String]()
        var currentMeetPlaces = [Int]()
        var currentMeetScores = [Double]()
        
        for index in 2..<data.count {
            let row = data[index]
            let firstCol = row[0]
            
            // If the first column contains a ".", it's a meet event title
            if firstCol.contains(".") {
                // Get the event title
                let eventTitle = firstCol.components(separatedBy: " - ")[0]
                // Get the place and score
                
                guard let placeScoreStr = row.last, let placeScoreMatch = try? NSRegularExpression(pattern: "([A-Z\\d]+)\\s+(\\d+.\\d+)").firstMatch(in: placeScoreStr, options: [], range: NSRange(location: 0, length: placeScoreStr.count)), placeScoreMatch.numberOfRanges == 3, let placeRange = Range(placeScoreMatch.range(at: 1), in: placeScoreStr), let scoreRange = Range(placeScoreMatch.range(at: 2), in: placeScoreStr) else {
                    print("Error: Invalid place at index \(row.count - 1)")
                    return nil
                }
                
                let place = Int(placeScoreStr[placeRange]) ?? 0
                let score = Double(placeScoreStr[scoreRange]) ?? 0.0
                
                currentMeetEvents.append(eventTitle)
                currentMeetPlaces.append(place)
                currentMeetScores.append(score)
            } else {
                // If the first column doesn't contain ".", it's a meet name
                // Save the previous meet's data
                if !currentMeetName.isEmpty {
                    let meet = Meet(meetName: currentMeetName, meetEvents: currentMeetEvents, meetPlaces: currentMeetPlaces, meetScores: currentMeetScores)
                    meets.append(meet)
                    currentMeetEvents.removeAll()
                    currentMeetPlaces.removeAll()
                    currentMeetScores.removeAll()
                }
                
                // Set the current meet name
                currentMeetName = firstCol
            }
        }
        
        // Save the last meet's data
        if !currentMeetName.isEmpty {
            let meet = Meet(meetName: currentMeetName, meetEvents: currentMeetEvents, meetPlaces: currentMeetPlaces, meetScores: currentMeetScores)
            meets.append(meet)
        }
        
        var updated_meets = [Meet]()
        meets.forEach{ meet in
            if meet.meetName == "Dive Statistics" {
                return
            }
            if meet.meetName == "Dive & Height Description High Score Avg Score # of Times" {
                return
            }
            else {
                updated_meets.append(meet)
            }
        }
        return updated_meets
    }



    var body: some View {
        
        //diverData[1][0] is [DIVEMEETS.COM History]
        ZStack{}
            .onAppear{
                diverData = parser.parse(urlString: profileLink)
                print(diverData)
                print(createMeets(data: diverData) as Any)
            }
        let rowColor: Color = currentMode == .light
                ? Color.white
                : Color.black
                
                NavigationView {
                    ZStack {
                        /// Background color for View
                        Color.clear.background(.thinMaterial)
                            .ignoresSafeArea()
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: rowSpacing) {
                                ForEach(createMeets(data: diverData) ?? [], id: \.meetName) { meet in
                                    NavigationLink(
                                        destination: MeetPage(meetInstance: meet)) {
                                            GeometryReader { geometry in
                                                HStack {
                                                    MeetElement(meet0: meet)
                                                        .foregroundColor(.primary)
                                                        .padding()
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(.secondary)
                                                        .padding()
                                                }
                                                .frame(width: frameWidth,
                                                       height: frameHeight)
                                                .background(rowColor)
                                                .cornerRadius(cornerRadius)
                                            }
                                            .frame(width: frameWidth,
                                                   height: frameHeight)
                                        }
                                }
                            }
                            /// Scroll tracking to hide/show tab bar when scrolling down/up
                            .overlay(
                                
                                GeometryReader {proxy -> Color in
                                    
                                    let minY = proxy.frame(in: .named("SCROLL")).minY
                                    
                                    /// Duration to hide TabBar
                                    let durationOffset: CGFloat = 0
                                    
                                    DispatchQueue.main.async {
                                        if minY < offset {
                                            if (offset < 0 &&
                                                -minY > (lastOffset + durationOffset)) {
                                                withAnimation(.easeOut.speed(1.5)) {
                                                    hideTabBar = true
                                                }
                                                lastOffset = -offset
                                            }
                                        }
                                        if offset < minY {
                                            if (offset < 0 &&
                                                -minY < (lastOffset - durationOffset)) {
                                                withAnimation(.easeIn.speed(1.5)) {
                                                    hideTabBar = false
                                                }
                                                lastOffset = -offset
                                            }
                                        }
                                        self.offset = minY
                                    }
                                    return Color.clear
                                }
                            )
                            .padding()
                        }
                        .coordinateSpace(name: "SCROLL")
                        .navigationTitle("Meets")
                    }
                }
            }
}
