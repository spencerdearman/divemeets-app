//
//  MeetPredictor.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 6/1/23.
//

import SwiftUI
import Foundation


func lookupInformation(forKey key: String) -> String? {
    if let url = Bundle.main.url(forResource: "diveTable", withExtension: "json") {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            let decodedData = try decoder.decode([String: DiveData].self, from: data)
            
            if let diveData = decodedData[key] {
                let name = diveData.name
                let difficulty = diveData.dd["3"] // Height
                
                return "Dive: \(name), Degree of Difficulty: \(difficulty ?? 0.0)"
            } else {
                return nil
            }
        } catch {
            print("Error decoding JSON: \(error)")
        }
    }
    
    return nil
}

struct MeetPredictor: View {
    var body: some View {
        VStack {
            Text("Meet Scores Predictor")
                .font(.title)
                .bold()
            Text(lookupInformation(forKey: "109C") ?? "No information found")
                .padding()
        }
    }
}

struct DiveData: Codable {
    let name: String
    let dd: [String: Double]
}


