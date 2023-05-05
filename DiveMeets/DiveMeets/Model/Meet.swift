//
//  Meet.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import Foundation
import SwiftUI

struct Meet: Hashable {

    var meetName: String
    var meetEvents: [String]
    var meetPlaces: [Int]
    var meetScores: [Double]
    var events: [Meet]?
    var isOpen: Bool = false
}

struct MeetEvent: Hashable, Identifiable {

    let id = UUID()
    let name: String
    var place: Int?
    var score: Double?
    var children: [MeetEvent]?
    var isOpen: Bool = false
    var isChild: Bool = false
}
