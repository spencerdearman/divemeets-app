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
    @State var diverData: [[String]] = []
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    @State var meets: [MeetEvent] = []
    @StateObject private var parser = HTMLParser()
    
    // Style adjustments for elements of list
    private let frameWidth: CGFloat = 350
    private let frameHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 10
    private let fontSize: CGFloat = 20
    let startIndex = 2
    
    private var customGray: Color {
        let gray = currentMode == .light ? 0.95 : 0.1
        return Color(red: gray, green: gray, blue: gray)
    }
    
    func createMeets(data: [[String]]) -> [MeetEvent]? {
        if data.count < 2 {
            return nil
        }
        
        var meets = [MeetEvent]()
        var currentMeetName = ""
        var currentMeetEvents: [MeetEvent]?
        var currentMeetPlaces: Int?
        var currentMeetScores: Double?
        
        for index in 2..<data.count {
            let row = data[index]
            let firstCol = row[0]
            
            // If the first column contains a ".", it's a meet event title
            if firstCol.contains(".") {
                // Get the event title
                let eventTitle = firstCol.components(separatedBy: " - ")[0]
                // Get the place and score
                
                guard let placeScoreStr = row.last,
                      let placeScoreMatch = try? NSRegularExpression(
                        pattern: "([A-Z\\d]+)\\s+(\\d+.\\d+)")
                    .firstMatch(in: placeScoreStr, options: [],
                                range: NSRange(location: 0, length: placeScoreStr.count)),
                      placeScoreMatch.numberOfRanges == 3,
                      let placeRange = Range(placeScoreMatch.range(at: 1), in: placeScoreStr),
                      let scoreRange = Range(placeScoreMatch.range(at: 2), in: placeScoreStr) else {
                    print("Error: Invalid place at index \(row.count - 1)")
                    return nil
                }
                
                let place = Int(placeScoreStr[placeRange]) ?? 0
                let score = Double(placeScoreStr[scoreRange]) ?? 0.0
                
                if currentMeetEvents == nil{
                    currentMeetEvents = []
                }
                currentMeetEvents!.append(MeetEvent(name: eventTitle, place: place, score: score, isChild: true))

            } else {
                // If the first column doesn't contain ".", it's a meet name
                // Save the previous meet's data
                if !currentMeetName.isEmpty {
                    let meet = MeetEvent(name: currentMeetName, children: currentMeetEvents)
                    meets.append(meet)
                    currentMeetEvents = nil
                    currentMeetPlaces = nil
                    currentMeetScores = nil
                }
                // Set the current meet name
                currentMeetName = firstCol
            }
        }
        
        // Save the last meet's data
        if !currentMeetName.isEmpty {
            let meet = MeetEvent(name: currentMeetName, children: currentMeetEvents)
            meets.append(meet)
        }
        
        var updated_meets = [MeetEvent]()
        meets.forEach{ meet in
            if meet.name == "Dive Statistics" {
                return
            }
            if meet.name == "Dive & Height Description High Score Avg Score # of Times" {
                return
            }
            else {
                updated_meets.append(meet)
            }
        }
        return updated_meets
    }
    
    
    
    var body: some View {
        
        ZStack{}
            .onAppear {
                Task {
                    await parser.parse(urlString: profileLink)
                    diverData = parser.myData
                    meets = createMeets(data: diverData) ?? []
                    print(meets)
//                                        print(diverData)
                    //                    print(createMeets(data: diverData) as Any)
                }
            }
        
        let rowColor: Color = currentMode == .light
        ? Color.white
        : Color.black
        
        NavigationView {
            ZStack {
                // Background color for View
                customGray.ignoresSafeArea()
                
//                ScrollView(.vertical, showsIndicators: false) {
//                    VStack(spacing: rowSpacing) {
                        List($meets, children: \.children) { $meet in
                            (!meet.isChild ?
                             AnyView(
                                parentView(meet: $meet)
                             ) : AnyView(
                                childView(meet: $meet)
                             ))
                            .frame(width: frameWidth,
                                   height: meet.isOpen ? 400: 60)
                            }
                        }
//                    }
//                    .padding()
//                }
                .navigationTitle("Meets")
            }
        }
    }



struct childView: View{
    @Binding var meet: MeetEvent
    
    var body: some View{
        NavigationLink(destination: Event(meet: $meet)){
            Text(meet.name)
        }
    }
}

struct parentView: View{
    @Binding var meet: MeetEvent
    
    var body: some View{
        HStack {
            Image(systemName: "link")
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
            
            HStack {
                Text(meet.name)
            }
            .foregroundColor(.primary)
            .padding()
            
        }
    }
}
