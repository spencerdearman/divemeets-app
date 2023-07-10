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

enum CustomError: Error {
    case FormatError
}

//                       [key   : [elements]
typealias MeetPageData = [String: [Element]]

//                        [(date  , number, name, rule , entriesLink)]
typealias MeetEventData = [(String, Int, String, String, String)]

//                               [(name  , link  , entries, date)]
typealias MeetResultsEventData = [(String, String, Int, String)]

//                        [(name  , team  , link  , [events])]
typealias MeetDiverData = [(String, String, String, [String])]

//                        [name  , team  , coachLink]
typealias MeetCoachData = [(String, String, String)]

typealias MeetInfoData = [String: String]

//                           [day   : [warmup/event start/end: time]]
typealias MeetInfoTimeData = [String: [String: String]]

typealias MeetInfoJointData = (MeetInfoData, MeetInfoTimeData, MeetEventData?)

//                              [name  : link  ]
typealias MeetLiveResultsData = [String: String]

//                          (meetName, date, divers,        events              )
typealias MeetResultsData = (String, String, MeetDiverData?, MeetResultsEventData?, MeetLiveResultsData?)

// Corrects date formatting to consistent usage, e.g. Tuesday, May 16, 2023
func correctDateFormatting(_ str: String) throws -> String {
    let df = DateFormatter()
    let formatters = ["yyyy-MM-dd", "MM-dd-yyyy", "MMM dd, yyyy"]
    var date: Date? = nil
    
    for formatter in formatters {
        df.dateFormat = formatter
        date = df.date(from: str)
        
        if date != nil {
            break
        }
    }
    
    if date == nil {
        throw CustomError.FormatError
    }
    
    df.dateFormat = "EEEE, MMM d, yyyy"
    return df.string(from: date!)
}

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
    
    // Corrects date time formatting to consistent usage, e.g. Tuesday, May 16, 2023 5:00 PM
    private func correctDateTimeFormatting(_ input: String) throws -> String {
        let df = DateFormatter()
        let formatters = ["MM/dd/yyyy h:mm:ss a", "MM-dd-yyyy h:mm a", "MM/dd/yyyy h:mm:ss"]
        var date: Date? = nil
        var str: String = input
        
        // Adjusts for using "Noon" to denote 12 PM instead of writing 12 PM
        let removeCharacters: Set<Character> = ["N", "o", "n"]
        str.removeAll(where: { removeCharacters.contains($0) } )
        str = str.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.count < input.count {
            str += " PM"
        }
        
        for formatter in formatters {
            df.dateFormat = formatter
            date = df.date(from: str)
            
            if date != nil {
                break
            }
        }
        
        if date == nil {
            print("Date \(str) failed to format")
            throw CustomError.FormatError
        }
        
        df.dateFormat = "EEEE, MMM d, yyyy h:mm a"
        return df.string(from: date!)
    }
    
    private func correctTimeFormatting(_ str: String) throws -> String {
        let df = DateFormatter()
        df.dateFormat = "hh:mm a"
        let date = df.date(from: str)!
        
        df.dateFormat = "h:mm a"
        return df.string(from: date)
        
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
                        number = Int(text.components(separatedBy: " ").last ?? "0") ?? 0
                        continue
                    }
                    
                    let html = try e.html()
                        .replacingOccurrences(of: "&nbsp;", with: "***")
                        .replacingOccurrences(of: " - ", with: "")
                    let body = try SwiftSoup.parseBodyFragment(html).body()!
                    
                    let comps = try body.text().components(separatedBy: "***")
                    let name = comps[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let ruleLink = try body.getElementsByTag("a").first()?.attr("href")
                    let ruleHtml = try await textLoader.getText(url: URL(
                        string: leadingLink + ruleLink!)!)!
                    let tds = try SwiftSoup.parse(ruleHtml).body()!.getElementsByTag("td")
                    let rule = try tds[tds.count - 2].text()
                    
                    // Assigns entries to empty string if there are no entries
                    let entries: String
                    if try body.getElementsByTag("a").last()?.text() == "Rule" {
                        entries = ""
                    } else {
                        entries = try leadingLink +
                        (body.getElementsByTag("a").last()?.attr("href") ?? "")
                    }
                    
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
                    
                    guard let lastParen = text.lastIndex(of: ")") else { continue }
                    let rest = String(text[text.index(lastParen, offsetBy: 2)...])
                    
                    let name = String(text[text.startIndex...lastParen])
                    
                    let link = try leadingLink + event.getElementsByTag("a").attr("href")
                    
                    let secSplit = rest.components(separatedBy: " ")
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
    
    func getLiveResultsData(data: MeetPageData) -> MeetLiveResultsData? {
        var result: MeetLiveResultsData = [:]
        var name: String = ""
        var link: String = ""
        
        if let live = data["live"] {
            do {
                for elem in live {
                    name = ""
                    link = ""
                    
                    let nameElem = try elem.getElementsByTag("strong").first()
                    if let nameElem = nameElem {
                        name = try nameElem.text()
                    } else {
                        print("Could not get name from element")
                        continue
                    }
                    
                    let linkElem = try elem.getElementsByTag("a").first()
                    if let linkElem = linkElem {
                        link = try linkElem.attr("href")
                    } else {
                        print("Could not get link from element")
                        continue
                    }
                    
                    result[name] = leadingLink + link
                }
                
                return result
            } catch {
                print("Getting live results failed")
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
    
    func getMeetInfoData(data: MeetPageData) async -> MeetInfoJointData? {
        var infoResult: MeetInfoData = [:]
        var time: MeetInfoTimeData = [:]
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
                    if text.contains("Pool") {
                        let poolHtml = try res.html().replacingOccurrences(of: "<br>", with: "$")
                        text = try SwiftSoup.parseBodyFragment(poolHtml)
                            .body()!.text()
                            .replacingOccurrences(of: "$", with: "\n")
                    }
                    if !addToTime && text.components(separatedBy: ": ").count < 2 {
                        print("Text split failed for: ", text)
                        continue
                    }
                    
                    let split = text.split(separator: ": ", maxSplits: 1)
                    var label = String(split[0])
                    var value = String(split[1])
                    
                    // Fix capitalization error for word "Date"
                    if label.contains("date") {
                        label = label.replacingOccurrences(of: "date", with: "Date")
                    }
                    // Fix inconsistent spacing after $
                    if value.contains("$ ") {
                        value = value.replacingOccurrences(of: "$ ", with: "$")
                    }
                    
                    if addToTime {
                        if time[curDay] == nil {
                            time[curDay] = [:]
                        }
                        time[curDay]![label] = try correctTimeFormatting(value)
                    } else if label.contains("Online Signup Closes at") {
                        let dateSplit = value.split(separator: "(", maxSplits: 1)
                        
                        let date = try correctDateTimeFormatting(String(dateSplit.first!)
                            .trimmingCharacters(in: .whitespacesAndNewlines))
                        infoResult[label] = date + " (" + dateSplit.last!
                    } else if label.contains("Date") {
                        let dateSplit = value.components(separatedBy: " ")
                        
                        let date = try correctDateFormatting(dateSplit.first!)
                        infoResult[label] = date
                    } else if label.contains("Fee must be paid by") {
                        let dateSplit = value.components(separatedBy: " ")
                        let dateTime = dateSplit[..<3].joined(separator: " ")
                        
                        let date = try correctDateTimeFormatting(dateTime)
                        infoResult[label] = date + " (Local Time)"
                    } else {
                        infoResult[label] = value
                    }
                }
                
                return (infoResult, time, await getEventData(data: data))
            } catch {
                print("Getting meet info data failed, \(error) caught")
            }
        }
        
        return nil
    }
    
    func getMeetResultsData(data: MeetPageData) async -> MeetResultsData? {
        var name: String = ""
        var date: String = ""
        var divers: MeetDiverData?
        var events: MeetResultsEventData?
        var liveResults: MeetLiveResultsData?
        
        do {
            if let nameElem = data["name"] {
                name = try nameElem.first!.getElementsByTag("strong").text()
            } else {
                return nil
            }
            if let dateElem = data["date"] {
                date = try dateElem.first!.getElementsByTag("strong").text()
            } else {
                return nil
            }
            if let diversList = getDiverListData(data: data) {
                divers = diversList
            }
            if let eventsList = getResultsEventData(data: data) {
                events = eventsList
            }
            if let liveResultsDict = getLiveResultsData(data: data) {
                liveResults = liveResultsDict
            }
            
            return (name, date, divers, events, liveResults)
        } catch {
            print("Getting meet results data failed")
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
            
            let live = try tables[0].getElementsByAttributeValue("style", "font-size: 10px").array()
            if !live.isEmpty {
                result["live"] = live
            }
            
            if tables.count < 2 { return nil }
            let lowerRows = try tables[1].getElementsByTag("tr")
            result["divers"] = []
            
            for r in lowerRows {
                if let first = lowerRows.first(), r == first {
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
        guard let content = try body.getElementById("dm_content") else { return nil }
        let tables = try content.getElementsByTag("table")
        
        if (link.contains("meetinfo")) {
            return parseInfoPage(tables: tables)
        } else if (link.contains("meetresults")) {
            return parseResultsPage(tables: tables)
        }
        
        return nil
    }
}
