//
//  MeetParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/22/23.
//

import SwiftUI
import SwiftSoup

private enum Stage: Int, CaseIterable {
    case upcoming
    case past
}

//                    Year  :  Org   :  Name  : Link
typealias MeetDict = [String: [String: [String: String]]]
//                           Name  : Link Type ("info" or "results") : Link
//                                   Note: "results" key not always present
typealias CurrentMeetDict = [String: [String: String]]
//                           Meet  :  Event : LiveResults object
typealias LiveResultsDict = [String: [String: LiveResults]]


final class MeetParser: ObservableObject {
    let currentYear = String(Calendar.current.component(.year, from: Date()))
    @Published private var linkText: String?
    // Upcoming meets happening in the future
    @Published var upcomingMeets: MeetDict?
    // Meets that are actively happening during that time period
    @Published var currentMeets: CurrentMeetDict?
    // Current meets that have live results available on their results page
    @Published var liveResults: LiveResultsDict?
    // Meets that have already happened
    @Published var pastMeets: MeetDict?
    @Published private var pastYear: String = ""
    @Published private var stage: Stage?
    let loader = GetTextAsyncLoader()
    let getTextModel = GetTextAsyncModel()
    let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
    
    // Gets html text from async loader
    private func fetchLinkText(url: URL) async {
        let text = try? await loader.getText(url: url)
        await MainActor.run {
            self.linkText = text
        }
    }
    
    // Gets the list of meet names and links to their pages from an org page
    private func getMeetNamesAndLinks(text: String) -> [String: String]? {
        var result: [String: String]?
        
        do {
            let document: Document = try SwiftSoup.parse(text)
            guard let body = document.body() else { return [:] }
            let content = try body.getElementById("dm_content")!
            let rows = try content.getElementsByTag("td")
            for row in rows {
                // Only continues on rows w/o align field and w valign == top
                if !(try !row.hasAttr("align")
                     && row.hasAttr("valign") && row.attr("valign") == "top") {
                    continue
                }
                
                /// Gets divs from page (meet name on past meets where link is "Results")
                let divs = try row.getElementsByTag("div")
                
                /// Gets links from list of meets
                let elem = try row.getElementsByTag("a")
                for e in elem {
                    if try e.tagName() == "a"
                        && e.attr("href").starts(with: "meet") {
                        if result == nil {
                            result = [:]
                        }
                        
                        let keyText = try divs.isEmpty() ? e.text() : divs[0].text()
                        result![keyText] = try leadingLink + e.attr("href")
                        break
                    }
                }
            }
        } catch {
            print("Parse failed")
        }
        
        if result != nil {
            print("Result:", result!)
        }
        
        return result
    }
    
    // Decomposes a row's children into a list of strings
    private func decomposeRow(row: Element) -> [String] {
        var result: [String] = []
        do {
            let children = row.children()
            for child in children {
                result.append(try child.text())
            }
            return result
        } catch {
            print("Decomposing row failed")
            return []
        }
    }
    
    // Parses the header from live results with the current and last diver into
    // LiveResultsDiver objects
    func parseLiveHeader(elem: Element) -> (LiveResultsDiver?, LiveResultsDiver?) {
        
        // TODO
        
        return (nil, nil)
    }
    
    // Saves a LiveResults object into the liveResults dict
    func saveLiveResults(meetName: String, eventName: String,
                         results: LiveResults) async {
        await MainActor.run {
            if liveResults == nil {
                liveResults = [:]
            }
            if liveResults![meetName] == nil {
                liveResults![meetName] = [:]
            }
            liveResults![meetName]![eventName]! = results
        }
    }
    
    // Parses a live event that is in progress and saves the LiveResults object
    // to the liveResults dict
    func parseActiveLiveEvent(meetName: String, eventName: String,
                              url: String) async {
        await getTextModel.fetchText(url: URL(string: url)!)
        
        do {
            let document: Document = try SwiftSoup.parse(getTextModel.text!)
            guard let body = document.body() else {
                return
            }
            let table = try body.getElementById("Results")
            let rows = try table?.getElementsByTag("tr")
            // Row with last and current diver
            let liveHeader = rows![1]
            let (currentDiver, lastDiver) = parseLiveHeader(elem: liveHeader)
            
            // Row with "Current Round: x/6
            let currentRoundRow = rows![2]
            print("Row Text:", try currentRoundRow.text())
            print("Current Round Row:", try currentRoundRow.html())
            //            wrapRoundCounter(currentRoundRow.html())
            
            var result: LiveResults = LiveResults(meetName: meetName,
                                                  eventName: eventName,
                                                  link: url,
                                                  currentRound: 1,
                                                  currentDiver: currentDiver,
                                                  lastDiver: lastDiver,
                                                  isFinished: false)
            
            // Row with column headers
            let columnsRow = rows![3]
            let columns: [String] = decomposeRow(row: columnsRow)
            print("Columns:", columns)
            
            for (idx, row) in rows!.enumerated() {
                if idx < 4 || idx == rows!.count - 1 {
                    continue
                }
                let rowVals: [String] = decomposeRow(row: row)
                print("Row:", rowVals)
                
                result.rows.append(Dictionary(
                    uniqueKeysWithValues: zip(columns, rowVals)))
            }
            
            print(result)
            await saveLiveResults(meetName: meetName, eventName: eventName,
                                  results: result)
        } catch {
            print("Parsing active live event failed")
        }
    }
    
    // Parses a live event that has already completed for a current meet and
    // saves it to the liveResults dict
    private func parseFinishedLiveEvent(meetName: String, eventName: String,
                                        url: String) async {
        await getTextModel.fetchText(url: URL(string: url)!)
        var result: LiveResults = LiveResults(meetName: meetName,
                                              eventName: eventName,
                                              link: url,
                                              isFinished: true)
        
        do {
            let document: Document = try SwiftSoup.parse(getTextModel.text!)
            guard let body = document.body() else {
                return
            }
            let table = try body.getElementById("Results")
            let rows = try table?.getElementsByTag("tr")
            
            for row in rows! {
                print("Row:", try row.text())
            }
            let columnsRow = rows![2]
            print("before")
            let columns: [String] = decomposeRow(row: columnsRow)
            print("Columns:", columns)
            
            for (idx, row) in rows!.enumerated() {
                if idx < 3 || idx == rows!.count - 1 {
                    continue
                }
                let rowVals: [String] = decomposeRow(row: row)
                
                result.rows.append(Dictionary(
                    uniqueKeysWithValues: zip(columns, rowVals)))
            }
            print(result)
            await saveLiveResults(meetName: meetName, eventName: eventName,
                                  results: result)
        } catch  {
            print("Parsing finished live event failed")
        }
    }
    
    // Parses the live event table from a live event in a current meet, whether
    // it is in progress or already completed
    private func parseLiveEventTable(meetName: String, eventName: String,
                                     url: String) async {
        let eventStatus: String
        // Pulls either -Started or Finished from end of URL
        let suffix = url.suffix(8)
        
        // Removes leading - from suffix string if -Started
        if suffix.hasPrefix("-") {
            eventStatus = String(suffix.suffix(7))
        } else {
            eventStatus = String(suffix)
        }
        
        if eventStatus == "Started" {
            print("Parsing active live")
            await parseActiveLiveEvent(meetName: meetName, eventName: eventName,
                                       url: url)
        } else if eventStatus == "Finished" {
            print("Parsing finished live")
            await parseFinishedLiveEvent(meetName: meetName, eventName: eventName,
                                         url: url)
        }
    }
    
    // Takes in a URL to a meet results page and updates the liveResults dict
    // with LiveResults objects for each event in that meet
    private func parseLiveEventsLinks(meetName: String, url: URL) async {
        await getTextModel.fetchText(url: url)
        
        do {
            let document: Document = try SwiftSoup.parse(getTextModel.text!)
            guard let body = document.body() else {
                return
            }
            let content = try body.getElementById("dm_content")
            let table = try content?.getElementsByTag("table").first()
            let rows = try table?.tagName("td").getElementsByAttribute("style")
            for row in rows! {
                if try row.attr("style") == "font-size: 10px" {
                    let eventName = try row.getElementsByTag("strong").first()!.text()
                    let results = try row.getElementsByTag("a")
                    let link = try leadingLink + results.attr("href")
                    await parseLiveEventTable(meetName: meetName,
                                              eventName: eventName, url: link)
                }
            }
            
            print("Live Results:", liveResults!)
        } catch {
            print("Parsing live results links failed")
            return
        }
    }
    
    // Parses current meets from homepage sidebar since "Current" tab is not
    // reliable
    private func parseCurrentMeets(html: String) async {
        var result: CurrentMeetDict = [:]
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                return
            }
            let content = try body.getElementById("dm_content")
            let sidebar = try content?.getElementsByTag("div")[3]
            // Gets table of all current meet rows
            let currentTable = try sidebar?.getElementsByTag("table")
                .first()?.children().first()
            // Gets list of Elements for each current meet
            let currentRows = try currentTable?.getElementsByTag("table")
            for row in currentRows! {
                let rowRows = try row.getElementsByTag("td")
                let meetElem = rowRows[0]
                var meetResults: Element? = nil
                if rowRows.count > 1 {
                    meetResults = rowRows[1]
                }
                result[try meetElem.text()] = [:]
                result[try meetElem.text()]!["info"] = try leadingLink +
                meetElem.getElementsByAttribute("href")[0].attr("href")
                if meetResults != nil {
                    result[try meetElem.text()]!["results"] =
                    try leadingLink + meetResults!.getElementsByAttribute("href")[0]
                        .attr("href")
                }
                await parseLiveEventsLinks(meetName: try meetElem.text(),
                                           url: URL(
                                            string: result[try meetElem.text()]!["results"]!)!)
            }
            
            await MainActor.run { [result] in
                currentMeets = result
            }
        } catch {
            print("Parsing current meets failed")
        }
    }
    
    // Parses the results page of an event in a past meet's results page
    private func parsePastMeetEventResults(eventName: String,
                                           link: String) async -> PastMeetEvent? {
        await getTextModel.fetchText(url: URL(string: link)!)
        var tableRows: [[String: String]] = []
        do {
            let document: Document = try SwiftSoup.parse(getTextModel.text!)
            guard let body = document.body() else { return nil }
            let content = try body.getElementById("dm_content")
            let table = try content?.getElementsByTag("table")[0]
            let rows = try table?.getElementsByTag("tr")
            let columnsRow = rows![3]
            let columns = decomposeRow(row: columnsRow)
            
            for (idx, row) in rows!.enumerated() {
                if idx < 5 || idx == rows!.count - 1 {
                    continue
                }
                let rowVals = decomposeRow(row: row)
                tableRows.append(Dictionary(
                    uniqueKeysWithValues: zip(columns, rowVals)))
            }
            
            return PastMeetEvent(eventName: eventName, eventLink: link, rows: tableRows)
        } catch {
            print("Parsing past meet event results failed")
        }
        return nil
    }
    
    // Parses the events of a past meet's results page
    // Note: This is not implemented in the automatic parsing of the Meets tabs
    // to avoid slow initial parsing times, but this should be called when a
    // meet results page is eventually loaded
    func parsePastMeetResults(meetName: String, link: String
    ) async -> PastMeetResults? {
        var events: [PastMeetEvent] = []
        do {
            events = []
            await getTextModel.fetchText(url: URL(string: link)!)
            let document: Document = try SwiftSoup.parse(getTextModel.text!)
            guard let body = document.body() else { return nil }
            let content = try body.getElementById("dm_content")
            let table = try content?.getElementsByTag("table")[0]
            let rows = try table?.getElementsByAttribute("bgcolor")
            
            for row in rows! {
                let event = try row.getElementsByTag("td")[0]
                let eventName = try event.text()
                let eventLink = try event.getElementsByTag("a")[0].attr("href")
                
                await events.append(
                    parsePastMeetEventResults(eventName: eventName,
                                              link: leadingLink + eventLink)!)
            }
            
            return PastMeetResults(meetName: meetName, meetLink: link, events: events)
        } catch {
            print("Parsing past meet results failed")
        }
        return nil
    }
    
    func parseMeets(html: String) async throws {
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                return
            }
            let menu = try body.getElementById("dm_menu_centered")
            let menuTabs = try menu?.getElementsByTag("ul")[0].getElementsByTag("li")
            for tab in menuTabs! {
                // tabElem is one of the links from the tabs in the menu bar
                let tabElem = try tab.getElementsByAttribute("href")[0]
                if try tabElem.text() == "Find" {
                    break
                }
                if try tabElem.text() == "Upcoming" {
                    await MainActor.run {
                        stage = .upcoming
                    }
                    continue
                }
                if try tabElem.text() == "Current" {
                    await parseCurrentMeets(html: html)
                    await MainActor.run {
                        stage = .past
                    }
                    continue
                }
                if try tabElem.text() == "Past Results & Photos" {
                    await MainActor.run {
                        stage = .past
                    }
                    continue
                }
                
                if stage == .upcoming {
                    if upcomingMeets == nil {
                        await MainActor.run {
                            upcomingMeets = [:]
                        }
                    }
                    if upcomingMeets![currentYear] == nil {
                        await MainActor.run {
                            upcomingMeets![currentYear] = [:]
                        }
                    }
                    
                    // tabElem.attr("href") is an organization link here
                    let link = try tabElem.attr("href")
                        .replacingOccurrences(of: " ", with: "%20")
                        .replacingOccurrences(of: "\t", with: "")
                    // Gets HTML from subpage link and sets linkText to HTML;
                    // This pulls the html for an org's page
                    await fetchLinkText(url: URL(string: link)!)
                    try await MainActor.run {
                        // Parses subpage and gets meet names and links
                        if let result = getMeetNamesAndLinks(text: linkText!) {
                            try upcomingMeets![currentYear]![tabElem.text()] = result
                        }
                    }
                }
                else if try stage == .past && tabElem.attr("href") == "#" {
                    try await MainActor.run {
                        pastYear = try tabElem.text()
                    }
                }
                else if stage == .past {
                    if pastMeets == nil {
                        await MainActor.run {
                            pastMeets = [:]
                        }
                    }
                    if pastMeets![pastYear] == nil {
                        await MainActor.run {
                            pastMeets![pastYear] = [:]
                        }
                    }
                    // tabElem.attr("href") is an organization link here
                    let link = try tabElem.attr("href")
                        .replacingOccurrences(of: " ", with: "%20")
                        .replacingOccurrences(of: "\t", with: "")
                    // Gets HTML from subpage link and sets linkText to HTML;
                    // This pulls the html for an org's page
                    await fetchLinkText(url: URL(string: link)!)
                    // Parses subpage and gets meet names and links
                    let namesAndLinks = getMeetNamesAndLinks(text: linkText!)
                    
                    try await MainActor.run { [namesAndLinks] in
                        // Assigns year and org to dict of meet names and
                        // links to results pagse
                        try pastMeets![pastYear]![tabElem.text()] = namesAndLinks
                    }
                }
            }
        } catch {
            print("Error parsing meets")
        }
    }
    
    func writeToFile(dict: [String: [String: String]],
                     filename: String = "saved.json") {
        let encoder = JSONEncoder()
        encoder.outputFormatting.insert(.sortedKeys)
        encoder.outputFormatting.insert(.prettyPrinted)
        
        do {
            let data = try encoder.encode(dict)
            let bundleURL = Bundle.main.resourceURL!
            
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
            let jsonObject = try decoder.decode([String: [String: String]].self,
                                                from: data)
            return jsonObject
        } catch {
            print("Read Error = \(error.localizedDescription)")
        }
        return [:]
    }
    
    func printPastMeets() {
        if pastMeets != nil {
            let keys = Array(pastMeets!.keys)
            let left = keys[0 ..< keys.count / 2]
            let right = keys[keys.count / 2 ..< keys.count]
            
            print("[")
            for k in left {
                print("\(k): \(pastMeets![k]!),")
            }
            for k in right {
                print("\(k): \(pastMeets![k]!),")
            }
            print("]")
        } else {
            print([String:String]())
        }
    }
}

struct MeetParserView: View {
    @StateObject private var getTextModel = GetTextAsyncModel()
    @StateObject private var p = MeetParser()
    @State var finishedParsing: Bool = false
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button("Upcoming") {
                    print(p.upcomingMeets ?? [:])
                }
                Spacer()
                Button("Current") {
                    print(p.currentMeets ?? [:])
                }
                Spacer()
                Button("Past") {
                    p.printPastMeets()
                }
                Spacer()
            }
            Spacer()
            
            if !finishedParsing {
                ProgressView()
            } else {
                Button("Print Past Meet Results") {
                    let meetName = "Phoenix Fall Classic @ UChicago"
                    let choice = p.pastMeets!["2022"]![
                        "National Collegiate Athletic Association (NCAA)"]![meetName]!
                    Task {
                        let result = await p.parsePastMeetResults(meetName: meetName,
                                                                  link: choice)
                        print(result!)
                    }
                    
                }
            }
            
            Spacer()
        }
        .onAppear {
            let url = URL(string: "https://secure.meetcontrol.com/divemeets/system/index.php")!
            
            Task {
                finishedParsing = false
                // This sets getTextModel's text field equal to the HTML from url
                await getTextModel.fetchText(url: url)
                // This sets p's upcoming, current, and past meets fields
                try await p.parseMeets(html: getTextModel.text!)
                finishedParsing = true
                print("Finished parsing")
            }
        }
    }
    
}
