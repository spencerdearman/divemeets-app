//
//  Home.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 4/25/23.
//

import SwiftUI

enum ViewType: String, CaseIterable {
    case upcoming = "Upcoming"
    case current = "Current"
}

func tupleToList(tuples: [MeetRecord]) -> [[String]] {
    var result: [[String]] = []
    //  (id, name, org, link, startDate, endDate, city, state, country)
    for (id, name, org, link, startDate, endDate, city, state, country) in tuples.sorted(
        by: { (lhs, rhs) in
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            
            // Sorts first by start date, then end date, then name in that order
            if lhs.4 == rhs.4 {
                if lhs.5 == rhs.5 {
                    return lhs.1! < rhs.1!
                }
                
                let a = lhs.5!
                let b = rhs.5!
                
                return df.date(from: a)! < df.date(from: b)!
            }
            
            let a = lhs.4!
            let b = rhs.4!
            
            return df.date(from: a)! < df.date(from: b)!
        }) {
        let idStr = id != nil ? String(id!) : ""
        result.append([idStr, name ?? "", org ?? "", link ?? "",
                       startDate ?? "", endDate ?? "", city ?? "", state ?? "", country ?? ""])
    }
    return result
}

struct Home: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.meetsDB) var db
    @StateObject var meetParser: MeetParser = MeetParser()
    @State private var meetsParsed: Bool = false
    @State private var selection: ViewType = .upcoming
    
    private let cornerRadius: CGFloat = 30
    private let textColor: Color = Color.primary
    private let grayValue: CGFloat = 0.90
    private let grayValueDark: CGFloat = 0.10
    @ScaledMetric private var typeBubbleWidth: CGFloat = 110
    @ScaledMetric private var typeBubbleHeight: CGFloat = 35
    @ScaledMetric private var typeBGWidth: CGFloat = 40
    
    private var typeBGColor: Color {
        currentMode == .light ? Color(red: grayValue, green: grayValue, blue: grayValue)
        : Color(red: grayValueDark, green: grayValueDark, blue: grayValueDark)
    }
    private var typeBubbleColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    
    @ViewBuilder
    var body: some View {
        NavigationView {
            ZStack {
                (currentMode == .light ? Color.white : Color.black)
                    .ignoresSafeArea()
                
                VStack {
                    VStack {
                        Text("Home")
                            .font(.title)
                            .bold()
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .frame(width: typeBubbleWidth * 2 + 5,
                                       height: typeBGWidth)
                                .foregroundColor(typeBGColor)
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .frame(width: typeBubbleWidth,
                                       height: typeBubbleHeight)
                                .foregroundColor(typeBubbleColor)
                                .offset(x: selection == .upcoming
                                        ? -typeBubbleWidth / 2
                                        : typeBubbleWidth / 2)
                                .animation(.spring(response: 0.2), value: selection)
                            HStack(spacing: 0) {
                                Button(action: {
                                    if selection == .current {
                                        selection = .upcoming
                                    }
                                }, label: {
                                    Text(ViewType.upcoming.rawValue)
                                        .animation(nil, value: selection)
                                })
                                .frame(width: typeBubbleWidth,
                                       height: typeBubbleHeight)
                                .foregroundColor(textColor)
                                .cornerRadius(cornerRadius)
                                Button(action: {
                                    if selection == .upcoming {
                                        selection = .current
                                    }
                                }, label: {
                                    Text(ViewType.current.rawValue)
                                        .animation(nil, value: selection)
                                })
                                .frame(width: typeBubbleWidth + 2,
                                       height: typeBubbleHeight)
                                .foregroundColor(textColor)
                                .cornerRadius(cornerRadius)
                            }
                        }
                    }
                    Spacer()
                    if selection == .upcoming {
                        UpcomingMeetsView(meetParser: meetParser)
                    } else {
                        CurrentMeetsView(meetParser: meetParser)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            if !meetsParsed {
                Task {
                    try await meetParser.parsePresentMeets()
                    meetsParsed = true
                }
            }
        }
    }
}

struct UpcomingMeetsView: View {
    @Environment(\.meetsDB) var db
    @ObservedObject var meetParser: MeetParser
    
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var body: some View {
        if meetParser.upcomingMeets != nil && !meetParser.upcomingMeets!.isEmpty {
            let upcoming = tupleToList(tuples: db.dictToTuple(dict: meetParser.upcomingMeets!))
            ScalingScrollView(records: upcoming) { (elem) in
                MeetBubbleView(elements: elem)
            }
            .padding(.bottom, maxHeightOffset)
        } else if meetParser.upcomingMeets != nil {
            Text("No upcoming meets found")
        } else {
            Text("Getting upcoming meets")
            ProgressView()
        }
    }
}


struct CurrentMeetsView: View {
    @Environment(\.meetsDB) var db
    @ObservedObject var meetParser: MeetParser
    
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var body: some View {
        if meetParser.currentMeets != nil && !meetParser.currentMeets!.isEmpty {
            let current = tupleToList(tuples: db.dictToTuple(dict: meetParser.currentMeets ?? []))
            ScalingScrollView(records: current) { (elem) in
                MeetBubbleView(elements: elem)
            }
            .padding(.bottom, maxHeightOffset)
        } else if meetParser.currentMeets != nil {
            Text("No current meets found")
        } else {
            Text("Getting current meets")
            ProgressView()
        }
    }
}

struct MeetBubbleView: View {
    @Environment(\.colorScheme) var currentMode
    
    private var bubbleColor: Color {
        currentMode == .light ? .white : .black
    }
    
    //  (id, name, org, link, startDate, endDate, city, state, country)
    private var elements: [String]
    
    init(elements: [String]) {
        self.elements = elements
    }
    
    var body: some View {
        NavigationLink(destination: MeetPageView(meetLink: elements[3])) {
            ZStack {
                Rectangle()
                    .foregroundColor(bubbleColor)
                VStack {
                    VStack {
                        Text(elements[1]) // name
                            .font(.title3)
                            .bold()
                            .scaledToFit()
                            .minimumScaleFactor(0.5)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(elements[2]) // org
                            .font(.headline)
                    }
                    .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack {
                        Text(elements[6] + ", " + elements[7]) // city, state
                        
                        Spacer()
                        
                        Text(elements[4] + " - " + elements[5]) // startDate - endDate
                    }
                    .font(.subheadline)
                    .scaledToFit()
                    .minimumScaleFactor(0.5)
                    .foregroundColor(.primary)
                }
                .padding()
            }
        }
        
    }
}
