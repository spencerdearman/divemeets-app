//
//  EventParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/5/23.
//

import SwiftUI
import SwiftSoup

final class EventHTMLParser: ObservableObject {
    @Published var myData = [Int:[String:[String:(String, Double, String)]]]()
    @Published var diveTableData = [Int: (String, String, String, Double, Double, Double, String)]()
    @Published var eventData: (String, String, String, Double, Double, Double) = ("","", "", 0.0, 0.0, 0.0)
    @Published var eventDictionary = [String:(String, Double, String)]()
    @Published var innerDictionary = [String:[String:(String, Double, String)]]()
    @Published var mainDictionary = [Int:[String:[String:(String, Double, String)]]]()
    @Published var meetScores = [Int: (String, String, String, Double, Double, Double, String)]()
    @Published var diveMeetTotals: (String, String, String, Double, Double, Double) = ("","", "", 0.0, 0.0, 0.0)
    //@Published var myData = [(String, Int, String)]()
    let getTextModel = GetTextAsyncModel()
    
    func parse(html: String) async throws -> [Int:[String:[String:(String, Double, String)]]] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return [:]
        }
        let main = try body.getElementsByTag("table")
        print("this is the HTML")
        
        //Getting the overarching td and then pulling the 3 items within
        let overall = try main[1].getElementsByTag("tr")
        var string = [String]()
        var eventLinkAppend = ""
        var counter = 0
        var meetEvent = ""
        var eventPlace = ""
        var eventScore = 0.0
        var eventLink = ""
        var meetName = ""
        for (i, t) in overall.enumerated(){
            var testString = try t.text()
            if i == 0 {
                continue
            } else if testString.contains(".") {
                meetEvent = try t.getElementsByTag("td")[0].text().replacingOccurrences(of: "  ", with: "")
                eventPlace = try t.getElementsByTag("td")[1].text().replacingOccurrences(of: " ", with: "")
                eventScore = Double(try t.getElementsByTag("td")[2].text())!
                eventLinkAppend = try t.getElementsByTag("a").attr("href")
                eventLink = "https://secure.meetcontrol.com/divemeets/system/" + eventLinkAppend
                string.append(try t.text())
                eventDictionary[meetEvent] = (eventPlace, eventScore, eventLink)
            } else if counter != 0 {
                innerDictionary[meetName] = eventDictionary
                mainDictionary[counter] = innerDictionary
                meetName = try t.text()
                innerDictionary = [:]
                eventDictionary = [:]
                counter += 1
            } else {
                meetName = try t.text()
                counter += 1
            }
        }
        return mainDictionary
    }
    
    func parseEvent(html: String) async throws -> (String, String, String, Double, Double, Double) {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return ("", "", "", 0.0, 0.0, 0.0)
        }
        
        var meetPageLink = ""
        var meetDates = ""
        var organization = ""
        var totalNetScore = 0.0
        var totalDD  = 0.0
        var totalScore = 0.0
        
        let main = try body.getElementsByTag("body")
        let table = try body.getElementsByTag("table")
        let overall = try table[0].getElementsByTag("tr")
        //Getting the link to the meet page, not to be confused with the meetLink --Working
        
        for (i, t) in overall.enumerated(){
            if i == 0 {
                var meetPageLink = "https://secure.meetcontrol.com/divemeets/system/" + (try t.getElementsByTag("a").attr("href"))
            } else if i == 1 {
                //Eventually go back and remove repeats
                meetDates = try t.getElementsByTag("Strong").text()
            } else if i == 3 {
                let temp = try t.getElementsByTag("Strong").text()
                let range = temp.range(of: " - ")
                organization = String(temp.suffix(from: range!.upperBound))
            }
        }
        let finalRow = try overall[overall.count - 2].getElementsByTag("td")
        for (i, tr) in finalRow.enumerated() {
            print(tr)
            if i == 2 {
                totalNetScore = Double(try tr.text())!
            } else if i == 3 {
                totalDD = Double(try tr.text())!
            } else if i == 4 {
                totalScore = Double(try tr.text())!
            }
        }
        diveMeetTotals = (meetPageLink, meetDates, organization, totalNetScore, totalDD, totalScore)
        return diveMeetTotals
    }
    
    
    func parseDiveTable(html: String) async throws -> [Int: (String, String, String, Double, Double, Double, String)] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return [:]
        }
        
        //Variable Hell
        var order = 0
        var diveNum = ""
        var height = ""
        var name = ""
        var netScore = 0.0
        var DD = 0.0
        var score = 0.0
        var scoreLink = ""
        
        let main = try body.getElementsByTag("body")
        let table = try body.getElementsByTag("table")
        let diveTable = try table[0].getElementsByAttribute("bgcolor")
        for dive in diveTable {
            let diveInformation = try dive.getElementsByTag("td")
            for (i, cell) in diveInformation.enumerated() {
                if i == 0 {
                    order = Int(try cell.text())!
                } else if i == 1 {
                    diveNum = try cell.text()
                } else if i == 2 {
                    height = try cell.text()
                } else if i == 3 {
                    name = try cell.text()
                } else if i == 4 {
                    netScore = Double(try cell.text())!
                } else if i == 5 {
                    DD = Double(try cell.text())!
                } else if i == 6 {
                    score = Double(try cell.text())!
                    scoreLink = "https://secure.meetcontrol.com/divemeets/system/" + (try cell.getElementsByTag("a").attr("href"))
                }
            }
            //(String, String, String, Double, Double, Double, String)
            meetScores[order] = (diveNum, height, name, netScore, DD, score, scoreLink)
        }
        return meetScores
    }
    
    func parse(urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        // This sets getTextModel's text field equal to the HTML from url
        await getTextModel.fetchText(url: url)
        
        if let html = getTextModel.text {
            do {
                let data = try await parse(html: html)
                await MainActor.run {
                    myData = data
                }
            } catch {
                print("Error parsing HTML: \(error)")
            }
        } else {
            print("Could not fetch text")
        }
    }
    
    func eventParse(urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        // This sets getTextModel's text field equal to the HTML from url
        await getTextModel.fetchText(url: url)
        
        if let html = getTextModel.text {
            do {
                let data = try await parseEvent(html: html)
                let tableData = try await parseDiveTable(html: html)
                await MainActor.run {
                    eventData = data
                    diveTableData = tableData
                }
            } catch {
                print("Error parsing HTML: \(error)")
            }
        } else {
            print("Could not fetch text")
        }
    }
}
