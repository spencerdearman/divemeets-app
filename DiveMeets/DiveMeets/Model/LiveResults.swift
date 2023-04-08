//
//  LiveResults.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/7/23.
//

import Foundation
// LeftToDive, Order, Last Rd Pl, Last Rd Score, Place, Cur Score, Name, Last Dv Avg, Event Avg, Rd Avg, 1st, 2nd, 3rd, Nxt
//typealias LiveResultsRow = (Bool, Int, Int, Double, Int, Double, String, Double, Double, Double, Double, Double, Double, Double)



class LiveResults {
    var meetName: String
    var eventName: String
//    var currentRound: Int
//    var currentDiver: LiveResultsDiver
//    var lastDiver: LiveResultsDiver
    var rows: [[String: String]]
    var isFinished: Bool
    
    init(meetName: String, eventName: String, rows: [[String: String]] = [], isFinished: Bool = true) {
        self.meetName = meetName
        self.eventName = eventName
        self.rows = rows
        self.isFinished = isFinished
    }
}
