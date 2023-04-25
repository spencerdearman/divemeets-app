//
//  PastMeetResults.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/10/23.
//

import Foundation

struct PastMeetEvent {
    var eventName: String
    var eventLink: String
    let columnLabels: [String] = ["Diver", "Team", "Place", "Score", "Diff"]
    // Rows from results ordered by place first->last
    var rows: [[String: String]]
}

struct PastMeetResults {
    var meetName: String
    var meetLink: String
    var events: [PastMeetEvent]
}
