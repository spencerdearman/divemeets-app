//
//  EntriesParser.swift
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

class EntriesParser: ObservableObject {
    @Published var entries: [EventEntry]?
    private let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
    
    func parseEntries(html: String) async throws -> [EventEntry]? {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else { return nil }
        let content = try body.getElementById("dm_content")
        let tables = try content?.getElementsByTag("table")
        
        var result: [EventEntry]?
        do {
            if tables?.count ?? 0 < 2 { return nil }
            if let rows = try tables?[1].getElementsByTag("tr") {
                var entry: EventEntry = EventEntry()
                for r in rows {
                    let bolds = try r.getElementsByTag("strong")
                    if bolds.count > 0 {
                        let sublinks = try bolds[0].getElementsByTag("a")
                        
                        // Row with diver name and potentially board label
                        if sublinks.count > 0 && sublinks[0].hasAttr("href") {
                            let links = try bolds[0].getElementsByTag("a")
                            if links.count > 1 {
                                let name = try links[0].text().components(separatedBy: ", ")
                                entry.firstName = name[1]
                                entry.lastName = name[0]
                                entry.link = try leadingLink + links[0].attr("href")
                                entry.team = try links[1].text()
                            }
                            
                            if bolds.count > 1 {
                                entry.board = try bolds[1].text().components(separatedBy: ": ").last
                            }
                            
                        } else if try bolds[0].text().contains("DD Total") {
                            // Row with DD Total and value
                            if bolds.count > 1 {
                                entry.totalDD = try Double(bolds[1].text())
                            }
                            
                            if result == nil {
                                result = []
                            }
                            result!.append(entry)
                            entry = EventEntry()
                            
                        } else {
                            // Row with headers can be skipped
                            continue
                        }
                    } else {
                        let vals = try r.getElementsByTag("td")
                        if vals.count > 4 {
                            let dive: EntryDive = try EntryDive(
                                number: vals[1].text(),
                                height: Int(String(vals[2].text().dropLast())) ?? 0,
                                name: vals[3].text(),
                                dd: Double(vals[4].text()) ?? 0.0)
                            if entry.dives == nil {
                                entry.dives = []
                            }
                            entry.dives!.append(dive)
                        }
                    }
                    
                    //                    print(try r.text())
                }
                
                //                result.append(entry)
                print("----------------------------")
                //            result["name"] = [upperRows[0]]
                //            result["date"] = [upperRows[1]]
                //            result["events"] = try tables[0].getElementsByAttribute("bgcolor").array()
                //
                //            if tables.count < 2 { return nil }
                //            let lowerRows = try tables[1].getElementsByTag("tr")
                //            result["divers"] = []
                //
                //            for r in lowerRows {
                //                if r == lowerRows.first()! {
                //                    continue
                //                }
                //                result["divers"]!.append(r)
                //            }
                //                print(result[0])
                return result
            }
        } catch {
            print("Results page parse failed")
        }
        
        return nil
    }
}

struct EntryDive: Hashable {
    var number: String
    var height: Int
    var name: String
    var dd: Double
}

struct EventEntry: Hashable {
    static func == (lhs: EventEntry, rhs: EventEntry) -> Bool {
        return lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName &&
               lhs.team == rhs.team && lhs.link == rhs.link && lhs.dives == rhs.dives &&
               lhs.totalDD == rhs.totalDD && lhs.board == rhs.board
    }
    
    var firstName: String?
    var lastName: String?
    var team: String?
    var link: String?
    var dives: [EntryDive]?
    var totalDD: Double?
    var board: String?
}
