//
//  ScoringParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/18/23.
//

import SwiftUI
import SwiftSoup

final class ScoreHTMLParser: ObservableObject {
    @Published var scoreData = [Int: Double]()
    
    let getTextModel = GetTextAsyncModel()
    
    func parse(html: String) async throws -> [Int: Double] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return [:]
        }
        let main = try body.getElementsByTag("tbody")
        //let scores = try main[0].getElementsByTag("tr")
        let scores = try main.select("td[style*=color:000000]")
        var value = 0.0
        for (i, t) in scores.enumerated() {
            //starting at 1 for the key because matching judge number
            value = Double(try t.text()) ?? 0.0
            await MainActor.run { [value] in
                scoreData[i + 1] = value
            }
        }
        return scoreData
    }
    
    func parse(urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        // This sets getTextModel's text field equal to the HTML from url
        await getTextModel.fetchText(url: url)
        
        if let html = getTextModel.text {
            do {
                let data = try await parse(html: html)
                await MainActor.run {
                    scoreData = data
                }
            } catch {
                print("Error parsing HTML: \(error)")
            }
        } else {
            print("Could not fetch text")
        }
    }
}
