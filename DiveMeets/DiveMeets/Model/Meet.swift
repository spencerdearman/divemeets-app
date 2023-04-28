//
//  Meet.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import Foundation
import SwiftUI

struct Meet: Hashable, Codable {

    var meetName: String
    var meetEvents: [String]
    var meetPlaces: [Int]
    var meetScores: [Double]
    var isOpen: Bool = false
}
