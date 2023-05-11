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
    for (_, name, org, _, startDate, _, city, state, _) in tuples {
//        let idStr = id != nil ? String(id!) : ""
        result.append([name ?? "", org ?? "",
                       startDate ?? "", city ?? "", state ?? ""])
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
            GeometryReader { mainView in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 15) {
                        ForEach(upcoming, id: \.self) { meet in
                            GeometryReader { item in
                                ZStack {
                                    Rectangle()
                                        .foregroundColor(.white)
                                    HStack {
                                        ForEach(meet, id: \.self) { col in
                                            if !col.starts(with: "http") {
                                                Text(col)
                                            }
                                        }
                                    }
                                    .padding()
                                }
                                .cornerRadius(15)
                                .scaleEffect(scaleValue(mainFrame: mainView.frame(in: .global).minY,
                                                        minY: item.frame(in: .global).minY),
                                             anchor: .bottom)
                                .opacity(scaleValue(mainFrame: mainView.frame(in: .global).minY,
                                                    minY: item.frame(in: .global).minY))
                            }
                            .frame(height: 100)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 25)
                }
                .zIndex(1)
            }
            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
            .padding(.bottom, maxHeightOffset)
        } else if meetParser.upcomingMeets != nil {
            Text("No upcoming meets found")
        } else {
            Text("Getting upcoming meets")
            ProgressView()
        }
    }
    
    func scaleValue(mainFrame: CGFloat, minY: CGFloat) -> CGFloat {
        withAnimation(.easeOut) {
            let scale = (minY - 25) / mainFrame

            if scale > 1 {
                return 1
            } else {
                return scale
            }
        }
    }
}


struct CurrentMeetsView: View {
    @Environment(\.meetsDB) var db
    @ObservedObject var meetParser: MeetParser
    
    var body: some View {
        if meetParser.currentMeets != nil && !meetParser.currentMeets!.isEmpty {
            let current = tupleToList(tuples: db.dictToTuple(dict: meetParser.currentMeets ?? []))
            List(current, id: \.self) { meet in
                HStack {
                    ForEach(meet, id: \.self) { col in
                        Text(col)
                    }
                }
            }
        } else if meetParser.currentMeets != nil {
            Text("No current meets found")
        } else {
            Text("Getting current meets")
            ProgressView()
        }
    }
}
