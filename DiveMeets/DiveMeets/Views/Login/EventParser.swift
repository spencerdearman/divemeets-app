//
//  EventParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/5/23.
//

import SwiftUI
import SwiftSoup

final class EventHTMLParser: ObservableObject {
    @Published var myData = String()
    let getTextModel = GetTextAsyncModel()
    
    func parse(html: String) async throws -> String {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return ""
        }
        let main = try body.getElementsByTag("table")
        print("this is the HTML")
        let myData = try main[1].getElementsByTag("a").attr("href")
        
        return myData
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
