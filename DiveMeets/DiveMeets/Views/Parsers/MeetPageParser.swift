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

//                               [(name  , link  , entries, date)]
typealias MeetResultsEventData = [(String, String, Int, String)]

//                        [(name  , team  , link  , [events])]
typealias MeetDiverData = [(String, String, String, [String])]

//                        [name  , team  , coachLink]
typealias MeetCoachData = [(String, String, String)]

typealias MeetInfoData = [String: String]

//                           [day   : [warmup/event start/end: time]]
typealias MeetInfoTimeData = [String: [String: String]]

typealias MeetInfoJointData = (MeetInfoData, MeetInfoTimeData)

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
    
    // Corrects date formatting to consistent usage, e.g. Tuesday, May 16, 2023
    private func correctDateFormatting(_ str: String) throws -> String {
        let df = DateFormatter()
        let formatters = ["yyyy-MM-dd", "MM-dd-yyyy"]
        var date: Date? = nil
        
        for formatter in formatters {
            df.dateFormat = formatter
            date = df.date(from: str)
            
            if date != nil {
                break
            }
        }
        
        if date == nil {
            throw NSError()
        }
        
        df.dateFormat = "EEEE, MMM d, yyyy"
        return df.string(from: date!)
    }
    
    // Corrects date time formatting to consistent usage, e.g. Tuesday, May 16, 2023 5:00 PM
    private func correctDateTimeFormatting(_ str: String) throws -> String {
        let df = DateFormatter()
        let formatters = ["MM/dd/yyyy h:mm:ss a"]
        var date: Date? = nil
        
        for formatter in formatters {
            df.dateFormat = formatter
            date = df.date(from: str)
            
            if date != nil {
                break
            }
        }
        
        if date == nil {
            throw NSError()
        }
        
        df.dateFormat = "EEEE, MMM d, yyyy h:mm a"
        return df.string(from: date!)
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
                    // This line catches cases where results events are passed into this function
                    if e == events.first! && !containsDayOfWeek(text) { return nil }
                    
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
    
    func getResultsEventData(data: MeetPageData) -> MeetResultsEventData? {
        var result: MeetResultsEventData = []
        
        if let events = data["events"] {
            do {
                for event in events {
                    let text = try event.text()
                    
                    // This line catches cases where info events are passed into this function
                    if event == events.first! && containsDayOfWeek(text) { return nil }
                    
                    let nameSplit = text.components(separatedBy: ") ")
                    var name = nameSplit[0]
                    name.append(")")
                    
                    let link = try leadingLink + event.getElementsByTag("a").attr("href")
                    
                    let secSplit = nameSplit.last!.components(separatedBy: " ")
                    let entries = Int(secSplit.first!)!
                    
                    // Converts date to proper format, then turns back into string
                    let date = try correctDateFormatting(secSplit.last!)
                    
                    result.append((name, link, entries, date))
                }
                
                return result
            } catch {
                print("Getting results event data failed")
            }
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
    
    func getMeetInfoData(data: MeetPageData) -> (MeetInfoData, MeetInfoTimeData)? {
        var infoResult: [String: String] = [:]
        var time: [String: [String: String]] = [:]
        var curDay: String = ""
        var addToTime: Bool = false
        
        if let info = data["info"] {
            do {
                for res in info {
                    var text = try res.text()
                    if text.starts(with: "Fee to be paid") {
                        continue
                    }
                    
                    // Gets elements with center alignment (the dates for each warmup/event time)
                    let elems = try res.getElementsByAttribute("align").filter {
                        try $0.attr("align") == "center"
                    }
                    
                    if elems.count > 0 {
                        curDay = try elems.first!.text()
                        addToTime = true
                        continue
                    }
                    if text.contains("In order to") {
                        text = text.replacingOccurrences(of: "(In order to avoid late fee) ", with: "")
                    }
                    if !addToTime && text.components(separatedBy: ": ").count < 2 {
                        print("Text split failed for: ", text)
                        continue
                    }
                    
                    var split = text.components(separatedBy: ": ")
                    // Fix capitalization error for word "Date"
                    if split[0].contains("date") {
                        split[0] = split[0].replacingOccurrences(of: "date", with: "Date")
                    }
                    // Fix inconsistent spacing after $
                    if split[1].contains("$ ") {
                        split[1] = split[1].replacingOccurrences(of: "$ ", with: "$")
                    }
                    
                    if addToTime {
                        if time[curDay] == nil {
                            time[curDay] = [:]
                        }
                        time[curDay]![split[0]] = split[1]
                    } else if split[0].contains("Online Signup Closes at") {
                        let dateSplit = split[1].split(separator: " ", maxSplits: 1)
                        
                        let date = try correctDateFormatting(String(dateSplit.first!))
                        infoResult[split[0]] = date + " " + dateSplit.last!
                    } else if split[0].contains("Date") {
                        let dateSplit = split[1].components(separatedBy: " ")

                        let date = try correctDateFormatting(dateSplit.first!)
                        infoResult[split[0]] = date
                    } else if split[0].contains("Fee must be paid by") {
                        let dateSplit = split[1].components(separatedBy: " ")
                        let dateTime = dateSplit[..<3].joined(separator: " ")
                        
                        let date = try correctDateTimeFormatting(dateTime)
                        infoResult[split[0]] = date + " (Local Time)"
                    } else {
                        infoResult[split[0]] = split[1]
                    }
                }
                
                return (infoResult, time)
            } catch {
                print("Getting meet info data failed")
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
                result["info"]!.append(r)
            }
            result["info"]!.removeLast()
            
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
                    result["events"]!.append(t)
                } else if stage == .divers {
                    result["divers"]!.append(t)
                } else {
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
            result["events"] = try tables[0].getElementsByAttribute("bgcolor").array()
            
            if tables.count < 2 { return nil }
            let lowerRows = try tables[1].getElementsByTag("tr")
            result["divers"] = []
            
            for r in lowerRows {
                if r == lowerRows.first()! {
                    continue
                }
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
