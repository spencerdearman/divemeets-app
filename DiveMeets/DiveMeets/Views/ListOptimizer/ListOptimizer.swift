//
//  ListOptimizer.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/31/23.
//

import SwiftUI
import Foundation

struct ListOptimizer: View {
    var body: some View {
        // Call the function with a key and display the retrieved information
        Text(lookupInformation(forKey: "101A") ?? "No information found")
            .padding()
    }
    
    func lookupInformation(forKey key: String) -> String? {
        if let url = Bundle.main.url(forResource: "diveTable", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                
                let decodedData = try decoder.decode(YourDataStructure.self, from: data)
                
                if let diveData = decodedData.data[key] {
                    let name = diveData.name
                    let difficulty = diveData.dd["1"] // Replace "1" with the desired difficulty level
                    
                    return "Name: \(name), Difficulty: \(difficulty ?? 0.0)"
                } else {
                    return nil
                }
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
        
        return nil
    }
}

struct YourDataStructure: Codable {
    struct DiveData: Codable {
        let name: String
        let dd: [String: Double]
    }
    
    let data: [String: DiveData]
}

