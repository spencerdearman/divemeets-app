//
//  NamesCreator.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 3/14/23.
//

import Foundation

func testNumbersAndCreateJSON() {
    // Define the URL string
    let urlString = "https://secure.meetcontrol.com/divemeets/system/profile.php?number="

    // Define the range of numbers to test
    let startNumber = 10000
    let endNumber = 70000

    // Create an array to store the results
    var resultsArray = [[String: String]]()

    // Loop through the numbers and attempt to retrieve the associated name
    for number in startNumber...endNumber {
        let numberString = String(number)
        if let url = URL(string: urlString + numberString), let data = try? Data(contentsOf: url) {
            if let htmlString = String(data: data, encoding: .utf8), let range = htmlString.range(of: "<h1>Profile: ") {
                let name = htmlString[range.upperBound...].prefix(while: { $0 != "<" })
                resultsArray.append(["Number": numberString, "Name": String(name)])
            }
        }
    }

    // Convert the results array to JSON data
    if let jsonData = try? JSONSerialization.data(withJSONObject: resultsArray, options: .prettyPrinted) {
        // Write the JSON data to a file
        let fileURL = URL(fileURLWithPath: "results.json")
        try? jsonData.write(to: fileURL)
    }
}

