//
//  EventPageParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/26/23.
//

import SwiftUI
import SwiftSoup

final class EventPageHTMLParser: ObservableObject {
    //                             Place  Name   NameLink  Team  TeamLink Score ScoreLink Score Diff.
    @Published var eventPageData = [Int: (String, String, String, String, Double, String, String)]()
    @Published var parsingPageData = [Int: (String, String, String, String, Double, String, String)]()

    let getTextModel = GetTextAsyncModel()

    func parseEventPage(html: String) async throws -> [Int: (String, String, String, String, Double, String, String)] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return [:]
        }

        var beginning = "https://secure.meetcontrol.com/divemeets/system/"
        var name = ""
        var partNameLink = ""
        var nameLink = ""
        var team = ""
        var partTeamLink = ""
        var teamLink = ""
        var score = 0.0
        var partScoreLink = ""
        var scoreLink = ""
        var scoreDifference = ""
        
        let table = try body.getElementsByTag("table")
        let overall = try table[0].getElementsByTag("tr")
        for (i, t) in overall.enumerated(){
            if 5 <= i && i < overall.count - 1 {
                let line = try t.getElementsByTag("td")
                name = try line[0].text()
                partNameLink = try line[0].getElementsByTag("a").attr("href")
                nameLink = beginning + partNameLink
                team = try line[1].text()
                partTeamLink = try line[1].getElementsByTag("a").attr("href")
                teamLink = beginning + partTeamLink
                score = Double(try line[3].text())!
                partScoreLink = try line[3].getElementsByTag("a").attr("href")
                scoreLink = beginning + partScoreLink
                scoreDifference = try line[4].text()
                await MainActor.run { [name, nameLink, team, teamLink, score, scoreLink, scoreDifference] in
                    parsingPageData[i - 4] = (name, nameLink, team, teamLink, score, scoreLink, scoreDifference)
                }
            }
        }
        print(parsingPageData)
        return parsingPageData
    }

    
    func parse(urlString: String) async {
        guard let url = URL(string: urlString) else { return }

        // This sets getTextModel's text field equal to the HTML from url
        await getTextModel.fetchText(url: url)

        if let html = getTextModel.text {
            do {
                let data = try await parseEventPage(html: html)
                await MainActor.run {
                    eventPageData = data
                }
            } catch {
                print("Error parsing HTML: \(error)")
            }
        } else {
            print("Could not fetch text")
        }
    }

}
