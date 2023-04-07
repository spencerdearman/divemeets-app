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

final class MeetParser: ObservableObject {
    let currentYear = String(Calendar.current.component(.year, from: Date()))
    @Published private var linkText: String?
    @Published var upcomingMeets: MeetDict?
    @Published var currentMeets: CurrentMeetDict?
    @Published var pastMeets: MeetDict?
    @Published private var pastYear: String = ""
    @Published private var stage: Stage?
    let loader = GetTextAsyncLoader()
    
    private func fetchLinkText(url: URL) async {
        let text = try? await loader.getText(url: url)
        await MainActor.run {
            self.linkText = text
        }
    }
    
    private func getMeetNamesAndLinks(text: String) -> [String: String]? {
        var result: [String: String]?
        let linkHead = "https://secure.meetcontrol.com/divemeets/system/"
        
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
                    if try e.tagName() == "a" && e.attr("href").starts(with: "meet") {
                        if result == nil {
                            result = [:]
                        }
                        
                        let keyText = try divs.isEmpty() ? e.text() : divs[0].text()
                        result![keyText] = try linkHead + e.attr("href")
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
    
    // Parses current meets from homepage sidebar since "Current" tab is not
    // reliable
    private func parseCurrentMeets(html: String) -> CurrentMeetDict? {
        var result: CurrentMeetDict = [:]
        let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                return nil
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
            }
            
            return result
        } catch {
            print("Parsing current meets failed")
            return nil
        }
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
                    await MainActor.run {
                        currentMeets = parseCurrentMeets(html: html)
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
                    let link = try tabElem.attr("href")
                        .replacingOccurrences(of: " ", with: "%20")
                        .replacingOccurrences(of: "\t", with: "")
                    // Gets HTML from subpage link and sets linkText to HTML
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
                    let link = try tabElem.attr("href")
                        .replacingOccurrences(of: " ", with: "%20")
                        .replacingOccurrences(of: "\t", with: "")
                    // Gets HTML from subpage link and sets linkText to HTML
                    await fetchLinkText(url: URL(string: link)!)
                    try await MainActor.run {
                        // Parses subpage and gets meet names and links
                        try pastMeets![pastYear]![tabElem.text()] =
                        getMeetNamesAndLinks(text: linkText!)
                    }
                }
            }
        } catch {
            print("Error parsing meets")
        }
    }
    
    func writeToFile(dict: [String: [String: String]], filename: String = "saved.json") {
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
            let jsonObject = try decoder.decode([String: [String: String]].self, from: data)
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
            Button("Check Parsing") {
                print(finishedParsing)
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
