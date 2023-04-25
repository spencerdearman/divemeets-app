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

struct ParseError: LocalizedError {
    let description: String
    
    init(_ description: String) {
        self.description = description
    }
    
    var errorDescription: String? {
        description
    }
}

//                    Year  :  Org   : [(Name  , Link  )]
typealias MeetDict = [String: [String: [(String, String)]]]
//                           [Name  :  Link Type ("info" or "results") : Link]
//                                   Note: "results" key not always present
typealias CurrentMeetDict = [[String: [String: String]]]
//                           Meet  :  Event : LiveResults object
typealias LiveResultsDict = [String: [String: LiveResults]]


// Decomposes a row's children into a list of strings
func decomposeRow(row: Element) -> [String] {
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
    @Published var meetsParsedCount: Int = 0
    @Published var totalMeetsParsedCount: Int = 0
    @Published var isFinishedCounting: Bool = false
    let loader = GetTextAsyncLoader()
    let getTextModel = GetTextAsyncModel()
    let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
    private var storedPastMeetYears: Set<Int>? = nil
    
    // Gets html text from async loader
    private func fetchLinkText(url: URL) async {
        let text = try? await loader.getText(url: url)
        await MainActor.run {
            self.linkText = text
        }
    }
    
    // Loads each stored year in the database into a set
    private func pullStoredPastMeetYears(storedMeets: FetchedResults<DivingMeet>) {
        storedPastMeetYears = Set<Int>(Array(storedMeets).map { Int($0.year) })
    }
    
    // Gets the list of meet names and links to their pages from an org page
    private func getMeetNamesAndLinks(text: String) -> [(String, String)]? {
        var result: [(String, String)]?
        do {
            let document: Document = try SwiftSoup.parse(text)
            guard let body = document.body() else { return [] }
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
                            result = []
                        }
                        
                        let nameText = try divs.isEmpty() ? e.text() : divs[0].text()
                        result!.append((nameText, try leadingLink + e.attr("href")))
                        break
                    }
                }
            }
        } catch {
            print("Parse failed")
        }
        
        return result
    }
    
    // Parses current meets from homepage sidebar since "Current" tab is not reliable
    private func parseCurrentMeets(html: String) async {
        var result: CurrentMeetDict = []
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
                var resultElem: [String: [String: String]] = [:]
                let rowRows = try row.getElementsByTag("td")
                let meetElem = rowRows[0]
                var meetResults: Element? = nil
                
                resultElem[try meetElem.text()] = [:]
                resultElem[try meetElem.text()]!["info"] = try leadingLink +
                meetElem.getElementsByAttribute("href")[0].attr("href")
                
                if rowRows.count > 1 {
                    meetResults = rowRows[1]
                    do {
                        let resultsLinks = try meetResults!.getElementsByAttribute("href")
                        let resultsLink: String
                        
                        if (resultsLinks.count == 0) {
                            throw ParseError("No results page found in row")
                        }
                        resultsLink = try resultsLinks[0].attr("href")
                        resultElem[try meetElem.text()]!["results"] = leadingLink + resultsLink
                    } catch {
                        print("No results page found")
                    }
                }
                
                result.append(resultElem)
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
        if let text = getTextModel.text {
            do {
                
                let document: Document = try SwiftSoup.parse(text)
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
        } else {
            print("Could not fetch model text")
        }
        return nil
    }
    
    // Parses the events of a past meet's results page
    // Note: This is not implemented in the automatic parsing of the Meets tabs
    // to avoid slow initial parsing times, but this should be called when a
    // meet results page is eventually loaded
    func parsePastMeetResults(meetName: String, link: String
    ) async -> PastMeetResults? {
        await getTextModel.fetchText(url: URL(string: link)!)
        var events: [PastMeetEvent] = []
        
        if let text = getTextModel.text {
            do {
                events = []
                
                let document: Document = try SwiftSoup.parse(text)
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
        } else {
            print("Could not fetch model text")
        }
        return nil
    }
    
    // Counts the meets to be parsed on a given HTML page
    private func countMeetNames(text: String) -> Int? {
        var count: Int = 0
        do {
            let document: Document = try SwiftSoup.parse(text)
            guard let body = document.body() else { return nil }
            let content = try body.getElementById("dm_content")!
            let rows = try content.getElementsByTag("td")
            for row in rows {
                // Only continues on rows w/o align field and w valign == top
                if !(try !row.hasAttr("align")
                     && row.hasAttr("valign") && row.attr("valign") == "top") {
                    continue
                }
                
                /// Gets links from list of meets
                let elem = try row.getElementsByTag("a")
                for e in elem {
                    if try e.tagName() == "a"
                        && e.attr("href").starts(with: "meet") {
                        count += 1
                        break
                    }
                }
            }
        } catch {
            print("Count failed")
        }
        
        return count
    }
    
    // Counts all of the current meets to be parsed
    private func countCurrentMeets(html: String) async -> Int? {
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else { return nil }
            let content = try body.getElementById("dm_content")
            let sidebar = try content?.getElementsByTag("div")[3]
            // Gets table of all current meet rows
            let currentTable = try sidebar?.getElementsByTag("table")
                .first()?.children().first()
            // Gets list of Elements for each current meet
            let currentRows = try currentTable?.getElementsByTag("table")
            if let rows = currentRows {
                return rows.count
            } else {
                return 0
            }
        } catch {
            print("Counting current meets failed")
        }
        
        return nil
    }
    
    // Counts all of the meets to be parsed from the meet parse on launch to provide an accurate
    // indexing progress bar
    private func countParsedMeets(
        html: String, storedMeets: FetchedResults<DivingMeet>? = nil) async throws {
            do {
                let document: Document = try SwiftSoup.parse(html)
                guard let body = document.body() else { return }
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
                        let currentMeetsCount = await countCurrentMeets(html: html)
                        await MainActor.run {
                            totalMeetsParsedCount += currentMeetsCount ?? 0
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
                        // tabElem.attr("href") is an organization link here
                        let link = try tabElem.attr("href")
                            .replacingOccurrences(of: " ", with: "%20")
                            .replacingOccurrences(of: "\t", with: "")
                        // Gets HTML from subpage link and sets linkText to HTML;
                        // This pulls the html for an org's page
                        await fetchLinkText(url: URL(string: link)!)
                        await MainActor.run {
                            // Parses subpage and gets meet names and links
                            if let text = linkText,
                               let result = countMeetNames(text: text) {
                                totalMeetsParsedCount += result
                            }
                        }
                    } else if try stage == .past && tabElem.attr("href") == "#" {
                        try await MainActor.run {
                            pastYear = try tabElem.text()
                        }
                    }
                    else if stage == .past {
                        // Gets a set of all past years currently in the database
                        if storedMeets != nil && storedPastMeetYears == nil {
                            pullStoredPastMeetYears(storedMeets: storedMeets!)
                        }
                        
                        // Skip years that are earlier than current year and already in the database
                        if Int(pastYear)! < Int(currentYear)!
                            && storedPastMeetYears!.contains(Int(pastYear)!) {
                            continue
                        }
                        
                        // tabElem.attr("href") is an organization link here
                        let link = try tabElem.attr("href")
                            .replacingOccurrences(of: " ", with: "%20")
                            .replacingOccurrences(of: "\t", with: "")
                        
                        // Gets HTML from subpage link and sets linkText to HTML;
                        // This pulls the html for an org's page
                        await fetchLinkText(url: URL(string: link)!)
                        
                        // Counts subpage and gets number of meet names
                        await MainActor.run {
                            if let text = linkText,
                               let result = countMeetNames(text: text) {
                                totalMeetsParsedCount += result
                            }
                        }
                    }
                }
            } catch {
                print("Error counting meets")
            }
            await MainActor.run {
                stage = nil
            }
        }
    
    // Parses the "Meets" tab from the homepage and stores results in MeetDict and CurrentMeetDict
    // objects to the respective fields in MeetParser
    func parseMeets(storedMeets: FetchedResults<DivingMeet>? = nil) async throws {
        do {
            // Initialize meet parse from index page
            let url = URL(string: "https://secure.meetcontrol.com/divemeets/system/index.php")!
            
            // This sets getTextModel's text field equal to the HTML from url
            await getTextModel.fetchText(url: url)
            
            if let html = getTextModel.text {
                try await countParsedMeets(html: html, storedMeets: storedMeets)
                await MainActor.run {
                    isFinishedCounting = true
                }
                
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
                            meetsParsedCount += (currentMeets ?? []).count
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
                                meetsParsedCount += result.count
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
                        
                        // Gets a set of all past years currently in the database
                        if storedMeets != nil && storedPastMeetYears == nil {
                            pullStoredPastMeetYears(storedMeets: storedMeets!)
                        }
                        
                        // Skip years that are earlier than current year and already in the database
                        if Int(pastYear)! < Int(currentYear)!
                            && storedPastMeetYears!.contains(Int(pastYear)!) {
                            continue
                        }
                        
                        // tabElem.attr("href") is an organization link here
                        let link = try tabElem.attr("href")
                            .replacingOccurrences(of: " ", with: "%20")
                            .replacingOccurrences(of: "\t", with: "")
                        
                        // Gets HTML from subpage link and sets linkText to HTML;
                        // This pulls the html for an org's page
                        await fetchLinkText(url: URL(string: link)!)
                        
                        // Parses subpage and gets meet names and links
                        try await MainActor.run {
                            // Assigns year and org to dict of meet names and
                            // links to results page
                            if let text = linkText,
                               let result = getMeetNamesAndLinks(text: text) {
                                try pastMeets![pastYear]![tabElem.text()] = result
                                meetsParsedCount += result.count
                            }
                        }
                    }
                }
            } else {
                print("Could not fetch html")
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
    @FetchRequest(sortDescriptors: []) var meets: FetchedResults<DivingMeet>
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
                    print(p.currentMeets ?? [])
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
                        "National Collegiate Athletic Association (NCAA)"]![0].1
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
            Task {
                finishedParsing = false
                
                // This sets p's upcoming, current, and past meets fields
                try await p.parseMeets(storedMeets: meets)
                
                finishedParsing = true
                print("Finished parsing")
            }
        }
    }
    
}
