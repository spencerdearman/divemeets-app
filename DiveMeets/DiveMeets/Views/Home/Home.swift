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
    @EnvironmentObject var meetParser: MeetParser
    
    var body: some View {
        List(tupleToList(tuples: db.dictToTuple(dict: meetParser.upcomingMeets ?? [:])),
             id: \.self) { meet in
            HStack {
                ForEach(meet, id: \.self) { col in
                    if !col.starts(with: "http") {
                        Text(col)
                    }
                }
            }
        }
    }
}
