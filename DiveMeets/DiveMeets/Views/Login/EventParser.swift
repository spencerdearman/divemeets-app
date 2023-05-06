//
//  EventParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/5/23.
//

import SwiftUI
import SwiftSoup

final class EventHTMLParser: ObservableObject {
    @Published var myData = [String:[String:(String, Double, String)]]()
    @Published var mainDictionary = [String:[String:(String, Double, String)]]()
    //@Published var myData = [(String, Int, String)]()
    let getTextModel = GetTextAsyncModel()
    
    func parse(html: String) async throws -> [String:[String:(String, Double, String)]] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return [:]
        }
        let main = try body.getElementsByTag("table")
        print("this is the HTML")
        
        //Getting the overarching td and then pulling the 3 items within
        let overall = try main[1].getElementsByTag("tr")
        var string = [String]()
        var meetEvent = ""
        var eventPlace = ""
        var eventScore = 0.0
        var eventLink = ""
        var meetName = ""
        for (i, t) in overall.enumerated(){
            var testString = try t.text()
            if i == 0 {
                continue
            }
            else if testString.contains(".") {
                meetEvent = try t.getElementsByTag("td")[0].text().replacingOccurrences(of: "  ", with: "")
                eventPlace = try t.getElementsByTag("td")[1].text()
                eventScore = Double(try t.getElementsByTag("td")[2].text())!
                eventLink = try t.getElementsByTag("a").attr("href")
                string.append(try t.text())
                mainDictionary[meetName] = [meetEvent: (eventPlace, eventScore, eventLink)]
            } else {
                meetName = try t.text()
                mainDictionary[meetName] = [String:(String, Double, String)]()
            }
        }
        return mainDictionary
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

    
}
