//
//  Profile.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import Foundation
import SwiftUI

struct Profile: Hashable, Codable {
    var firstName: String
    var lastName: String
    var school: String
    var division: String
    
    private var imageName: String
    var image: Image{
        Image(imageName)
    }
}
