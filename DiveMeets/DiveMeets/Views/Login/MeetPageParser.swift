//
//  MeetPageParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 5/28/23.
//

import Foundation
import SwiftSoup

private enum InfoStage {
    case events
    case divers
    case coaches
}

//                       [key   : [elements]
typealias MeetPageData = [String: [Element]]

//                        [(date  , number, name, rule , entries)]
typealias MeetEventData = [(String, Int, String, String, Int)]

//                        [(name  , team  , link  , [events])]
typealias MeetDiverData = [(String, String, String, [String])]

//                        [name  , team  , coachLink]
typealias MeetCoachData = [(String, String, String)]

class MeetPageParser: ObservableObject {
    @Published var meetData: MeetPageData?
    private let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
    
    private func containsDayOfWeek(_ str: String) -> Bool {
        let days: Set = Set(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])
        for d in days {
            if str.contains(d) {
                return true
            }
        }
        
        return false
    }
    
    private func getEventRule(link: String) async -> String? {
        let textModel: GetTextAsyncModel = GetTextAsyncModel()
        let url: URL = URL(string: link)!
        
        await textModel.fetchText(url: url)
        
        if let text = textModel.text {
            return text
        }
        
        return nil
    }
    
    func getEventData(data: MeetPageData) async -> MeetEventData? {
        let textLoader: GetTextAsyncLoader = GetTextAsyncLoader()
        var result: MeetEventData = []
        var date: String = ""
        var number: Int = 0
        var text: String = ""
        
        do {
            if let events = data["events"] {
                for e in events {
                    text = try e.text()
                    if date == "" || containsDayOfWeek(text) {
                        date = text
                        continue
                    }
                    if number == 0 || text.starts(with: "Event") {
                        number = Int(text.components(separatedBy: " ").last!)!
                        continue
                    }
                    
                    let html = try e.html()
                        .replacingOccurrences(of: "&nbsp;", with: "***")
                        .replacingOccurrences(of: " - ", with: "")
                    let body = try SwiftSoup.parseBodyFragment(html).body()!
                    
                    let comps = try body.text().components(separatedBy: "***")
                    let name = comps[0].components(separatedBy: "(").first!
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let entries = Int(comps.last!.components(separatedBy: " ").first!)!
                    
                    let ruleLink = try body.getElementsByTag("a").first()?.attr("href")
                    let ruleHtml = try await textLoader.getText(url: URL(
                        string: leadingLink + ruleLink!)!)!
                    let tds = try SwiftSoup.parse(ruleHtml).body()!.getElementsByTag("td")
                    let rule = try tds[tds.count - 2].text()
                    
                    result.append((date, number, name, rule, entries))
                }
                
                return result
            }
        } catch {
            print("Getting event data failed")
        }
        
        return nil
    }
    
    func getDiverListData(data: MeetPageData) -> MeetDiverData? {
        var result: MeetDiverData = []
        
        if let divers = data["divers"] {
            do {
                for diver in divers {
                    let text = try diver.text()
                    let noPlace = text.split(separator: ". ", maxSplits: 1).last!
                    let nameSplit = noPlace.components(separatedBy: " - ")
                    // Switches name order from Last, First to First Last
                    let name = nameSplit.first!.components(separatedBy: ", ")
                        .reversed()
                        .joined(separator: " ")
                    
                    let teamSplit = nameSplit.last!.split(separator: " ( ")
                    let team = String(teamSplit.first!)
                    
                    let link = try leadingLink + diver.getElementsByTag("a").attr("href")
                    
                    let eventsStr = teamSplit.last!
                    var events = eventsStr.components(separatedBy: " | ")
                    events[events.count - 1].removeLast(2)
                    
                    result.append((name, team, link, events))
                }
                
                return result
            } catch {
                print("Getting diver list data failed")
            }
        }
        
        return nil
    }
    
    func getCoachListData(data: MeetPageData) -> MeetCoachData? {
        var result: MeetCoachData = []
        
        if let coaches = data["coaches"] {
            do {
                for coach in coaches {
                    let text = try coach.text()
                    let noPlace = text.split(separator: ". ", maxSplits: 1).last!
                    let nameSplit = noPlace.components(separatedBy: " - ")
                    let name = nameSplit.last!
                    let team = nameSplit.first!
                    let link = try leadingLink + coach.getElementsByTag("a").attr("href")
                    
                    result.append((name, team, link))
                }
                
                return result
            } catch {
                print("Getting coach list data failed")
            }
        }
        
        return nil
    }
    
    // Produces a MeetPageData object with keys: coaches, divers, events, info
    private func parseInfoPage(tables: Elements) -> MeetPageData? {
        var result: MeetPageData = [:]
        
        var stage: InfoStage = .events
        do {
            if tables.count < 1 { return nil }
            let topTable = tables[0]
            result["info"] = []
            
            // Drops first element ("To sign up for this meet, please login." element)
            for r in try topTable.getElementsByTag("tr").dropFirst() {
                let text = try r.text()
                
                if text.contains("Note:") {
                    break
                }
                print(text)
                result["info"]!.append(r)
            }
            result["info"]!.removeLast()
            print("_____________________")
            
            if tables.count < 2 { return nil }
            let botTable = tables[1]
            result["events"] = []
            result["divers"] = []
            result["coaches"] = []
            
            for t in try botTable.getElementsByTag("tr") {
                if try t.text().contains("Divers Entered:") {
                    stage = .divers
                    continue
                }
                else if try t.text().contains("Coaches Registered:") {
                    stage = .coaches
                    continue
                }
                
                if stage == .events {
                    print(try "Event: " + t.text())
                    result["events"]!.append(t)
                } else if stage == .divers {
                    print(try "Diver: " + t.text())
                    result["divers"]!.append(t)
                } else {
                    print(try "Coach: " + t.text())
                    result["coaches"]!.append(t)
                }
            }
            
            return result
            
        } catch {
            print("Info page parse failed")
        }
        
        return nil
    }
    
    // Produces a MeetPageData object with keys: date, divers, events, names
    private func parseResultsPage(tables: Elements) -> MeetPageData? {
        var result: MeetPageData = [:]
        do {
            if tables.count < 1 { return nil }
            let upperRows = try tables[0].getElementsByTag("tr")
            result["name"] = [upperRows[0]]
            result["date"] = [upperRows[1]]
            print(try result["name"]![0].text())
            print(try result["date"]![0].text())
            result["events"] = try tables[0].getElementsByAttribute("bgcolor").array()
            for r in result["events"]! {
                print(try r.text())
            }
            print("_____________________")
            
            if tables.count < 2 { return nil }
            let lowerRows = try tables[1].getElementsByTag("tr")
            result["divers"] = []
            
            for r in lowerRows {
                if r == lowerRows.first()! {
                    continue
                }
                print(try r.text())
                result["divers"]!.append(r)
            }
            
            return result
        } catch {
            print("Results page parse failed")
        }
        
        return nil
    }
    
    func parseMeetPage(link: String, html: String) async throws -> MeetPageData? {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else { return nil }
        let content = try body.getElementById("dm_content")!
        let tables = try content.getElementsByTag("table")
        
        if (link.contains("meetinfo")) {
            print("Parsing info link...")
            return parseInfoPage(tables: tables)
        } else if (link.contains("meetresults")) {
            print("Parsing results link...")
            return parseResultsPage(tables: tables)
        }
        print("Failed")
        return nil
    }
}
