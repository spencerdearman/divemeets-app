//
//  LiveResultsParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/22/23.
//

//import SwiftUI
//import SwiftSoup
//
//final class LiveResultsParser: ObservableObject {
//    let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
//    @Binding var liveResultsLink: String
//    @Binding var liveResultsHTML: String
//    // Meets that are actively happening during that time period
//    @Published var currentMeets: CurrentMeetList?
//    // Current meets that have live results available on their results page
//    @Published var liveResults: LiveResultsDict?
//    let getTextModel = GetTextAsyncModel()
//    let sleepSeconds = 3
//
//    init(link: Binding<String>, html: Binding<String>) {
//        self._liveResultsLink = link
//        self._liveResultsHTML = html
//    }
//
//    // Parses the header from live results with the current and last diver into
//    // LiveResultsDiver objects
//    private func parseLiveHeader(elem: Element) -> (LiveResultsDiver?, LiveResultsDiver?) {
//
//        // TODO
//
//        return (nil, nil)
//    }
//
//    // Saves a LiveResults object into the liveResults dict
//    private func saveLiveResults(meetName: String, eventName: String,
//                                 results: LiveResults) async {
//        await MainActor.run {
//            if liveResults == nil {
//                liveResults = [:]
//            }
//            if liveResults![meetName] == nil {
//                liveResults![meetName] = [:]
//            }
//            liveResults![meetName]![eventName] = results
//        }
//    }
//
//    // Wraps text for current round in div so it can be processed as an Element
//    private func wrapLooseText(text: String) -> String {
//        do {
//            var result: String = text
//            let pattern = #"<\/strong>(?<round>[a-zA-z0-9\s&;:\/]+)<\/td>"#
//            let regex = try NSRegularExpression(pattern: pattern, options: [])
//            let nsrange = NSRange(text.startIndex..<text.endIndex,
//                                  in: text)
//
//            regex.enumerateMatches(in: text, range: nsrange) {
//                (match, _, _) in
//                guard let match = match else { return }
//                var capturedString = ""
//
//                let matchRange = match.range(withName: "round")
//                if let substringRange = Range(matchRange, in: text) {
//                    let capture = String(text[substringRange])
//                    capturedString = capture
//                }
//
//                capturedString = capturedString.trimmingCharacters(in: .whitespacesAndNewlines)
//                result = result.replacingOccurrences(of: capturedString,
//                                                     with: "<div>" + capturedString + "</div>")
//            }
//            return result
//        } catch {
//            print("Failed to parse text input")
//        }
//        return ""
//    }
//
//    // Parses a live event that is in progress and saves the LiveResults object
//    // to the liveResults dict
//    private func parseActiveLiveEvent(meetName: String, eventName: String,
//                                      url: String) async {
//        liveResultsLink = url
//        print("Assigned in live event \(meetName) \(eventName) \(url)")
//
//        do {
//            try await Task.sleep(until: .now + .seconds(sleepSeconds), clock: .continuous)
//            print("HTML FILLED? ", liveResultsHTML != "")
//            //            print(liveResultsHTML)
//
//            let parseText = liveResultsHTML
//            let document: Document = try SwiftSoup.parse(parseText)
//            liveResultsHTML = ""
//
//            guard let body = document.body() else {
//                return
//            }
//
//            let table = try body.getElementById("Results")
//            let tables = try table?.getElementsByTag("table")
//            let rows = try table?.getElementsByTag("tr")
//
//            // Bounds checking on parsed rows
//            if rows == nil || rows!.count < 7 {
//                throw ParseError("Live event rows did not contain enough elements")
//            }
//
//            for (idx, t) in tables!.enumerated() {
//                print("Table \(idx): ", try t.html())
//            }
//
//            // Row with last and current diver
//            let liveHeader = rows![2]
//            let (currentDiver, lastDiver) = parseLiveHeader(elem: liveHeader)
//
//            // TODO: figure this out, location in HTML is so inconsistent
//            // Row with "Current Round: x/6
//            //            let currentRoundTable = tables![0]
//            let currentRoundRow = rows![6]
//            print("Current Round Row:", try currentRoundRow.html())
//
//            let doc: Document = try SwiftSoup.parseBodyFragment(
//                wrapLooseText(text: try currentRoundRow.html()))
//
//            guard let wrappedText = try doc.body()?.getElementsByTag("div") else {
//                throw ParseError("Unable to get new wrapped text children")
//            }
//
//            print("Wrapped Row:", try wrappedText.html())
//            print("Wrapped Row Text:", try wrappedText.text())
//            print("____________________________")
//
//            var curRound: Int?
//            var totalRounds: Int?
//
//            if try wrappedText.text() != "" {
//                let rds = try wrappedText.text().split(separator: "/")
//                let r = rds.first
//                let tot = rds.last
//                if r != nil {
//                    curRound = Int(r?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "-1")!
//                }
//                if tot != nil {
//                    totalRounds = Int(tot?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "-1")!
//                }
//            }
//
//            print("Current Round: ", curRound)
//            print("Total Rounds: ", totalRounds)
//
//            var result: LiveResults = LiveResults(meetName: meetName,
//                                                  eventName: eventName,
//                                                  link: url,
//                                                  currentRound: curRound,
//                                                  totalRounds: totalRounds,
//                                                  currentDiver: currentDiver,
//                                                  lastDiver: lastDiver,
//                                                  isFinished: false)
//
//            // Row with column headers
//            let columnsRow = rows![3]
//            let columns: [String] = decomposeRow(row: columnsRow)
//
//            for (idx, row) in rows!.enumerated() {
//                if idx < 4 || idx == rows!.count - 1 {
//                    continue
//                }
//                let rowVals: [String] = decomposeRow(row: row)
//
//                result.rows.append(Dictionary(
//                    uniqueKeysWithValues: zip(columns, rowVals)))
//            }
//
//            await saveLiveResults(meetName: meetName, eventName: eventName,
//                                  results: result)
//        } catch {
//            print("Parsing active live event failed")
//        }
//    }
//
//    // Parses a live event that has already completed for a current meet and
//    // saves it to the liveResults dict
//    private func parseFinishedLiveEvent(meetName: String, eventName: String,
//                                        url: String) async {
//        liveResultsLink = url
//
//        print("Assigned in finished event \(meetName) \(eventName) \(url)")
//        var result: LiveResults = LiveResults(meetName: meetName,
//                                              eventName: eventName,
//                                              link: url,
//                                              isFinished: true)
//
//        do {
//            try await Task.sleep(until: .now + .seconds(sleepSeconds), clock: .continuous)
//            print("HTML FILLED? ", liveResultsHTML != "")
//            //            print(liveResultsHTML)
//
//            let parseText = liveResultsHTML
//            let document: Document = try SwiftSoup.parse(parseText)
//            liveResultsHTML = ""
//
//            guard let body = document.body() else {
//                return
//            }
//            let table = try body.getElementById("Results")
//            let rows = try table?.getElementsByTag("tr")
//
//            // Bounds checking on parsed rows
//            if rows == nil || rows!.count < 3 {
//                throw ParseError("Finished event rows did not contain enough elements")
//            }
//
//            let columnsRow = rows![2]
//            let columns: [String] = decomposeRow(row: columnsRow)
//
//            for (idx, row) in rows!.enumerated() {
//                if idx < 3 || idx == rows!.count - 1 {
//                    continue
//                }
//                let rowVals: [String] = decomposeRow(row: row)
//
//                result.rows.append(Dictionary(
//                    uniqueKeysWithValues: zip(columns, rowVals)))
//            }
//
//            await saveLiveResults(meetName: meetName, eventName: eventName,
//                                  results: result)
//        } catch  {
//            print("Parsing finished live event failed")
//        }
//    }
//
//    // Parses the live event table from a live event in a current meet, whether
//    // it is in progress or already completed
//    private func parseLiveEventTable(meetName: String, eventName: String,
//                                     url: String) async {
//        let eventStatus: String
//        // Pulls either -Started or Finished from end of URL
//        let suffix = url.suffix(8)
//
//        // Removes leading - from suffix string if -Started
//        if suffix.hasPrefix("-") {
//            eventStatus = String(suffix.suffix(7))
//        } else {
//            eventStatus = String(suffix)
//        }
//
//        if eventStatus == "Started" {
//            await parseActiveLiveEvent(meetName: meetName, eventName: eventName,
//                                       url: url)
//        } else if eventStatus == "Finished" {
//            await parseFinishedLiveEvent(meetName: meetName, eventName: eventName,
//                                         url: url)
//        }
//    }
//
//    // Takes in a URL to a meet results page and updates the liveResults dict
//    // with LiveResults objects for each event in that meet
//    // Note: This should be called only when loading a current meet page, it is
//    //         not called when parseCurrentMeets collects the meet page links
//    func parseLiveEventsLinks(meetName: String, url: URL) async {
//        await getTextModel.fetchText(url: url)
//        do {
//            let parseText = getTextModel.text ?? ""
//            if (parseText == "") {
//                throw ParseError("Unable to fetch text from url \(url)")
//            }
//
//            let document: Document = try SwiftSoup.parse(parseText)
//            guard let body = document.body() else {
//                return
//            }
//            let content = try body.getElementById("dm_content")
//            let table = try content?.getElementsByTag("table").first()
//            let rows = try table?.tagName("td").getElementsByAttribute("style")
//            for row in rows! {
//                if try row.attr("style") == "font-size: 10px" {
//                    let eventName = try row.getElementsByTag("strong").first()!.text()
//                    let results = try row.getElementsByTag("a")
//                    let link = try leadingLink + results.attr("href")
//                    await parseLiveEventTable(meetName: meetName,
//                                              eventName: eventName, url: link)
//                }
//            }
//
//            print("Live Results:", liveResults ?? [:])
//        } catch {
//            print("Parsing live results links failed")
//            return
//        }
//    }
//}
//
//struct LiveResultsParserView: View {
//    @State var link: String = "https://secure.meetcontrol.com/divemeets/system/index.php"
//    @State var html: String = ""
//    let loader = GetTextAsyncLoader()
//    let getTextModel = GetTextAsyncModel()
//    @State var finishedParsing: Bool = false
//
//    var body: some View {
//        ZStack {
//            LRWebView(request: $link, html: $html)
//        }
//        .onAppear {
//            let p = LiveResultsParser(link: $link, html: $html)
//            let url = URL(string: "https://secure.meetcontrol.com/divemeets/system/index.php")!
//            Task {
//                finishedParsing = false
//
//                await getTextModel.fetchText(url: url)
//
//                // TODO: add test call here for live result
//
//                finishedParsing = true
//                print(p.liveResults ?? [:])
//            }
//        }
//    }
//}
