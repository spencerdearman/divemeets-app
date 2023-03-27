//
//  MeetParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/22/23.
//

import SwiftUI
import SwiftSoup

enum Stage: Int, CaseIterable {
    case upcoming
    case past
}

final class MeetParser: ObservableObject {
    let currentYear = String(Calendar.current.component(.year, from: Date()))
    
    func parseMeets(html: String) -> ([String: [String: String]], String?, [String: [String: String]]) {
        var upcomingMeets: [String: [String: String]] = [:]
        var currentMeets: String? = nil
        var pastMeets: [String: [String: String]] = [:]
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                return ([:], "Failed to retrieve body", [:])
            }
            let menu = try body.getElementById("dm_menu_centered")
            let menuTabs = try menu?.getElementsByTag("ul")[0].getElementsByTag("li")
            print("--------------------MenuTabs!----------------")
            var stage: Stage?
            var pastYear: String = ""
            for tab in menuTabs! {
                let tabElem = try tab.getElementsByAttribute("href")[0]
                if try tabElem.text() == "Find" {
                    break
                }
                if try tabElem.text() == "Upcoming" {
                    stage = .upcoming
                    continue
                }
                if try tabElem.text() == "Current" {
                    currentMeets = try tabElem.attr("href")
                    stage = .past
                    continue
                }
                if try tabElem.text() == "Past Results & Photos" {
                    stage = .past
                    continue
                }
                
                if stage == .upcoming {
                    if upcomingMeets[currentYear] == nil {
                        upcomingMeets[currentYear] = [:]
                    }
                    try upcomingMeets[currentYear]![tabElem.text()] = tabElem.attr("href")
                }
                else if try stage == .past && tabElem.attr("href") == "#" {
                    pastYear = try tabElem.text()
                    /// Only saves last two years of past meets into dictionary, loads rest from static file
                    ///  Loads last two years to prevent any missing links when close to new year
                    if Int(pastYear) ?? 10000 < Int(currentYear)! - 1 {
                        break
                    }
                }
                else if stage == .past {
                    if pastMeets[pastYear] == nil {
                        pastMeets[pastYear] = [:]
                    }
                    try pastMeets[pastYear]![tabElem.text()] = tabElem.attr("href")
                }
            }
            
            /// Merges parsed pastMeets with static historical data, keeping the parsed version if the
            /// same key appears
            let loadedPastMeets = readFromFile(filename: "pastMeets.json")
            
            /// Merges years where both pastMeets and loadedPastMeets appear
            for k in pastMeets.keys {
                if loadedPastMeets[k] != nil {
                    pastMeets[k] = pastMeets[k]!.merging(
                        loadedPastMeets[k]!) { (current, _) in current }
                }
            }
            
            /// Adds years that were not parsed from loadedPastMeets
            pastMeets = pastMeets.merging(loadedPastMeets) { (current, _) in current }
            
            //            print("Upcoming")
            //            print(upcomingMeets)
            //            print("Current")
            //            print(currentMeets ?? "")
//            print("Past")
//            print(pastMeets)
            print("Before:", GlobalCache.profileMeetCache["test"] ?? [[]])
            GlobalCache.profileMeetCache["test"] = [["Logan", "Sherwin"]]
            try GlobalCache.profileMeetCache.saveToDisk(withName: "test")
            print("After:", GlobalCache.profileMeetCache["test"] ?? [[]])
            
            //            for k in upcomingMeets.keys.sorted(by: >) {
            //                print(k, ":", upcomingMeets[k]!.sorted(by: <).count)
            //            }
            print("---------------------------------------------")
            
        } catch {
            print("Error parsing meets")
        }
        
        return (upcomingMeets, currentMeets, pastMeets)
    }
    
    func writeToFile(dict: [String: [String: String]], filename: String = "saved.json") {
        let encoder = JSONEncoder()
        encoder.outputFormatting.insert(.sortedKeys)
        encoder.outputFormatting.insert(.prettyPrinted)
        
        do {
            let data = try encoder.encode(dict)
            let bundleURL = Bundle.main.resourceURL!
            //            print(bundleURL)
            
            let jsonFileURL = bundleURL.appendingPathComponent(filename)
            
            try data.write(to: jsonFileURL)
        } catch {
            print("Write Error = \(error.localizedDescription)")
        }
    }
    
    func readFromFile(filename: String) -> [String: [String: String]] {
        let decoder = JSONDecoder()
        let bundleURL = Bundle.main.resourceURL!.appendingPathComponent("pastMeets.json")
        do {
            let data = try Data(contentsOf: bundleURL)
            let jsonObject = try decoder.decode([String: [String: String]].self, from: data)
            return jsonObject
        } catch {
            print("Read Error = \(error.localizedDescription)")
        }
        return [:]
    }
}

struct MeetParserView: View {
    var text: String = ""
    let p: MeetParser = MeetParser()
    var body: some View {
        
        Button("Button") {
            let session = URLSession.shared
            let url = URL(string: "https://secure.meetcontrol.com/divemeets/system/index.php")!
            var upcoming: [String: [String: String]] = [:]
            var current: String?
            var past: [String: [String: String]] = [:]
            let task = session.dataTask(with: url) { data, response, error in
                // Check whether data is not nil
                guard let loadedData = data else { return }
                // Load HTML code as string
                let text = String(data: loadedData, encoding: .utf8)
                //                print(text!)
                
                (upcoming, current, past) = p.parseMeets(html: text!)
                //                p.writeToFile(dict: past, filename: "past_meets.json")
            }
            task.resume()
            
        }
    }
    
}

//struct MeetParserView_Previews: PreviewProvider {
//    static var previews: some View {
//        MeetParserView()
//    }
//}
