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
    @State var diverData: [Array<String>] = []
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    @Binding var hideTabBar: Bool
    @StateObject private var parser = HTMLParser()
    
    /// Style adjustments for elements of list
    private let frameWidth: CGFloat = 350
    private let frameHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 3
    private let fontSize: CGFloat = 20
    let startIndex = 2
    
    func createMeets(data: [[String]]) -> [Meet]? {
        if data.count < 2 {
            return nil
        }
        
        var meets = [Meet]()
        var currentMeetName = ""
        var currentMeetEvents = [String]()
        var currentMeetPlaces = [Int]()
        var currentMeetScores = [Double]()
        
        for index in 2..<data.count {
            let row = data[index]
            let firstCol = row[0]
            
            // If the first column contains a ".", it's a meet event title
            if firstCol.contains(".") {
                // Get the event title
                let eventTitle = firstCol.components(separatedBy: " - ")[0]
                
                // Get the place and score
                guard let placeScoreStr = row.last, let placeScoreMatch = try? NSRegularExpression(pattern: "(\\d+)\\s+(\\d+.\\d+)").firstMatch(in: placeScoreStr, options: [], range: NSRange(location: 0, length: placeScoreStr.count)), placeScoreMatch.numberOfRanges == 3, let placeRange = Range(placeScoreMatch.range(at: 1), in: placeScoreStr), let scoreRange = Range(placeScoreMatch.range(at: 2), in: placeScoreStr) else {
                    print("Error: Invalid place at index \(row.count - 1)")
                    return nil
                }
                
                let place = Int(placeScoreStr[placeRange]) ?? 0
                let score = Double(placeScoreStr[scoreRange]) ?? 0.0
                
                currentMeetEvents.append(eventTitle)
                currentMeetPlaces.append(place)
                currentMeetScores.append(score)
            } else {
                // If the first column doesn't contain ".", it's a meet name
                // Save the previous meet's data
                if !currentMeetName.isEmpty {
                    let meet = Meet(meetName: currentMeetName, meetEvents: currentMeetEvents, meetPlaces: currentMeetPlaces, meetScores: currentMeetScores)
                    meets.append(meet)
                    currentMeetEvents.removeAll()
                    currentMeetPlaces.removeAll()
                    currentMeetScores.removeAll()
                }
                
                // Set the current meet name
                currentMeetName = firstCol
            }
        }
        
        // Save the last meet's data
        if !currentMeetName.isEmpty {
            let meet = Meet(meetName: currentMeetName, meetEvents: currentMeetEvents, meetPlaces: currentMeetPlaces, meetScores: currentMeetScores)
            meets.append(meet)
        }
        
        return meets
    }



    var body: some View {
        
        //diverData[1][0] is [DIVEMEETS.COM History]
        ZStack{}
            .onAppear{
                diverData = parser.parse(urlString: profileLink)
                print(diverData)
                print(createMeets(data: diverData) as Any)
            }
        NavigationView {
            List {
                ForEach(createMeets(data: diverData) ?? [], id: \.meetName) { meet in
                    Text(meet.meetName)
                }
            }
        }
    }
}


/*
import SwiftUI

struct MeetList: View {
    @Environment(\.colorScheme) var currentMode
    var profileLink: String
    @State var diverData : [Array<String>] = []
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    @Binding var hideTabBar: Bool
    @StateObject private var parser = HTMLParser()
    
    
    /// Style adjustments for elements of list
    private let frameWidth: CGFloat = 350
    private let frameHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 3
    private let fontSize: CGFloat = 20
    let startIndex = 2
    
    
    func createMeets(data: [[String]]) -> [Meet]? {
        var meets = [Meet]()
        var currentMeetName = ""
        var currentMeetEvents = [String]()
        var currentMeetPlaces = [Int]()
        var currentMeetScores = [Double]()
        
        for row in data {
            let firstCol = row[0]
            
            // If the first column doesn't contain a number, it's a meet or event name
            if firstCol.rangeOfCharacter(from: CharacterSet.decimalDigits) == nil {
                // Save the previous meet's data
                if !currentMeetName.isEmpty {
                    let meet = Meet(meetName: currentMeetName, meetEvents: currentMeetEvents, meetPlaces: currentMeetPlaces, meetScores: currentMeetScores)
                    meets.append(meet)
                    currentMeetEvents.removeAll()
                    currentMeetPlaces.removeAll()
                    currentMeetScores.removeAll()
                }
                
                // Set the current meet name
                currentMeetName = row.joined(separator: " ")
            } else if let range = firstCol.range(of: #"20\d{2}"#, options: .regularExpression) {
                currentMeetName = String(firstCol[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                if !currentMeetName.isEmpty {
                    let meet = Meet(meetName: currentMeetName, meetEvents: currentMeetEvents, meetPlaces: currentMeetPlaces, meetScores: currentMeetScores)
                    meets.append(meet)
                    currentMeetEvents.removeAll()
                    currentMeetPlaces.removeAll()
                    currentMeetScores.removeAll()
                }
                // Get the year
                let year = String(firstCol[range])
                // Set the current meet name to include the year
                currentMeetName = "\(currentMeetName) \(year)"
            } else {
                // Otherwise, it's an event result
                // Get the event title
                let eventTitle = firstCol.components(separatedBy: " - ")[0]
                
                // Get the place and score
                guard let placeScoreStr = row.last, let placeScoreMatch = try? NSRegularExpression(pattern: "(\\d+)\\s+(\\d+.\\d+)").firstMatch(in: placeScoreStr, options: [], range: NSRange(location: 0, length: placeScoreStr.count)), placeScoreMatch.numberOfRanges == 3, let placeRange = Range(placeScoreMatch.range(at: 1), in: placeScoreStr), let scoreRange = Range(placeScoreMatch.range(at: 2), in: placeScoreStr) else {
                    print("Error: Invalid place at index \(row.count - 1)")
                    return nil
                }
                
                let place = Int(placeScoreStr[placeRange]) ?? 0
                let score = Double(placeScoreStr[scoreRange]) ?? 0.0
                
                currentMeetEvents.append(eventTitle)
                currentMeetPlaces.append(place)
                currentMeetScores.append(score)
            }
        }
        
        // Save the last meet's data
        if !currentMeetName.isEmpty {
            let meet = Meet(meetName: currentMeetName, meetEvents: currentMeetEvents, meetPlaces: currentMeetPlaces, meetScores: currentMeetScores)
            meets.append(meet)
        }
        return meets
    }
*/
