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

typealias MeetPageData = [String: String]

class MeetPageParser: ObservableObject {
    @Published var meetData: MeetPageData?
    
    private func parseInfoPage(tables: Elements) -> MeetPageData? {
        var stage: InfoStage = .events
        do {
            print("Info")
            if tables.count < 1 { return nil }
            let topTable = tables[0]
            var upperRows: [Element] = []
            
            for r in try topTable.getElementsByTag("tr") {
                let text = try r.text()
                if text.contains("Divers Entered:") {
                    break
                }
                print(text)
                upperRows.append(r)
            }
            print("_____________________")
            
            if tables.count < 2 { return nil }
            let botTable = tables[1]
            var events: [Element] = []
            var divers: [Element] = []
            var coaches: [Element] = []
            
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
                    events.append(t)
                } else if stage == .divers {
                    print(try "Diver: " + t.text())
                    divers.append(t)
                } else {
                    print(try "Coach: " + t.text())
                    coaches.append(t)
                }
            }
            print("_____________________")
            
            
        } catch {
            print("Info page parse failed")
        }
        
        return nil
    }
    
    private func parseResultsPage(tables: Elements) -> MeetPageData? {
        do {
            print("Results")
            if tables.count < 1 { return nil }
            let upperRows = try tables[0].getElementsByTag("tr")
            let meetName: String = try String(upperRows[0].text().split(separator: ": ").last!)
            let meetDate: String = try String(upperRows[1].text().split(separator: ": ").last!)
            print(meetName)
            print(meetDate)
            let events: Elements = try tables[0].getElementsByAttribute("bgcolor")
            for r in events {
                print(try r.text())
            }
            print("_____________________")
            
            if tables.count < 2 { return nil }
            let lowerRows = try tables[1].getElementsByTag("tr")
            var divers: [Element] = []
            
            for r in lowerRows {
                if r == lowerRows.first()! {
                    continue
                }
                print(try r.text())
                divers.append(r)
            }
            print("_____________________")
            
        } catch {
            print("Results page parse failed")
        }
        
        return nil
    }
    
    func parseMeetPage(link: String, html: String) async throws -> MeetPageData? {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else { return nil }
        print(link)
        let content = try body.getElementById("dm_content")!
        let tables = try content.getElementsByTag("table")
        
        if (link.contains("meetinfo")) {
            return parseInfoPage(tables: tables)
        } else if (link.contains("meetresults")) {
            return parseResultsPage(tables: tables)
        }
        print("Failed")
        return nil
    }
}
