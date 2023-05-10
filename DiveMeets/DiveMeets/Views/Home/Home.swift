//
//  Home.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 4/25/23.
//

import SwiftUI

func tupleToList(tuples: [MeetRecord]) -> [[String]] {
    var result: [[String]] = []
    for (id, name, org, link, startDate, endDate, city, state, country) in tuples {
        let idStr = id != nil ? String(id!) : ""
        result.append([idStr, name ?? "", org ?? "", link ?? "",
                       startDate ?? "", endDate ?? "", city ?? "", state ?? "", country ?? ""])
    }
    return result
}

struct Home: View {
    @Environment(\.meetsDB) var db
    @StateObject var meetParser: MeetParser = MeetParser()
    @State private var meetsParsed: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            if meetParser.upcomingMeets != nil && !meetParser.upcomingMeets!.isEmpty {
                let upcoming = tupleToList(tuples: db.dictToTuple(dict: meetParser.upcomingMeets!))
                List(upcoming, id: \.self) { meet in
                    HStack {
                        ForEach(meet, id: \.self) { col in
                            if !col.starts(with: "http") {
                                Text(col)
                            }
                        }
                    }
                }
            } else if meetParser.upcomingMeets != nil {
                Text("No upcoming meets found")
            } else {
                Text("Getting upcoming meets")
                ProgressView()
            }
            Spacer()
            if meetParser.currentMeets != nil && !meetParser.currentMeets!.isEmpty {
                let current = tupleToList(tuples: db.dictToTuple(dict: meetParser.currentMeets ?? []))
                List(current, id: \.self) { meet in
                    HStack {
                        ForEach(meet, id: \.self) { col in
                            if !col.starts(with: "http") {
                                Text(col)
                            }
                        }
                    }
                }
            } else if meetParser.currentMeets != nil {
                Text("No current meets found")
            } else {
                Text("Getting current meets")
                ProgressView()
            }
            Spacer()
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
