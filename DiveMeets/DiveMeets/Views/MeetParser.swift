//
//  MeetParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/22/23.
//

import SwiftUI
import SwiftSoup

final class MeetParser: ObservableObject {
    
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
            var stage: Int = 0
            var pastYear: String = ""
            for tab in menuTabs! {
                let tabElem = try tab.getElementsByAttribute("href")[0]
                if try tabElem.text() == "Find" {
                    break
                }
                if try tabElem.text() == "Upcoming" {
                    stage = 1
                    continue
                }
                if try tabElem.text() == "Current" {
                    currentMeets = try tabElem.attr("href")
                    stage = 2
                    continue
                }
                if try tabElem.text() == "Past Results & Photos" {
                    stage = 2
                    continue
                }
                
                if stage == 1 {
                    if upcomingMeets["2023"] == nil {
                        upcomingMeets["2023"] = [:]
                    }
                    try upcomingMeets["2023"]![tabElem.text()] = tabElem.attr("href")
                }
                else if try stage == 2 && tabElem.attr("href") == "#" {
                    pastYear = try tabElem.text()
                }
                else if stage == 2 {
                    if pastMeets[pastYear] == nil {
                        pastMeets[pastYear] = [:]
                    }
                    try pastMeets[pastYear]![tabElem.text()] = tabElem.attr("href")
                }
            }
            print("Upcoming")
            print(upcomingMeets)
            print("Current")
            print(currentMeets ?? "")
            print("Past")
            print(pastMeets)
//            for k in upcomingMeets.keys.sorted(by: >) {
//                print(k, ":", upcomingMeets[k]!.sorted(by: <).count)
//            }
            print("---------------------------------------------")
            
        } catch {
            print("Error parsing meets")
        }
        
        return (upcomingMeets, currentMeets, pastMeets)
    }
}

struct MeetParserView: View {
    var text: String = ""
    let p: MeetParser = MeetParser()
    var body: some View {
        
        Button("Button") {
            let session = URLSession.shared
            let url = URL(string: "https://secure.meetcontrol.com/divemeets/system/index.php")!
            let task = session.dataTask(with: url) { data, response, error in
                // Check whether data is not nil
                guard let loadedData = data else { return }
                // Load HTML code as string
                let text = String(data: loadedData, encoding: .utf8)
//                print(text!)
                p.parseMeets(html: text!)
            }
            task.resume()
//            while text == "" {
//                ""
//            }
            
        }
    }
    
}

//struct MeetParserView_Previews: PreviewProvider {
//    static var previews: some View {
//        MeetParserView()
//    }
//}
