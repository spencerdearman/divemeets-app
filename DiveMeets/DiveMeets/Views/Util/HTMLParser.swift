//
//  HTMLParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 3/14/23.
//

import SwiftUI
import SwiftSoup

final class HTMLParser: ObservableObject {
    @Published var myData = [[String]]()
    let getTextModel = GetTextAsyncModel()
    
    func parse(html: String) async throws -> [[String]] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return [[]]
        }
        let main = try body.getElementsByTag("body").compactMap({try? $0.html()})
        let html = main[0]
        let doc: Document = try SwiftSoup.parse(html)
        
        var myData = [[String]]()
        let myRows: Elements? = try doc.getElementsByTag("tr")
        try myRows?.forEach({ row in
            let tempString = try row.text()
            let split = tempString.components(separatedBy: "  ")
            myData.append(split)
        })
        
        return myData
    }
    
    func parseReturnString(html: String) -> String? {
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                return nil
            }
            let main = try body.getElementsByTag("body").compactMap({try? $0.html()})
            return main.first
        }
        catch {
            print("Error Parsing: " + String(describing: error))
            return nil
        }
    }
    
    func testingParser(urlString: String) -> String? {
        guard let url = URL(string: urlString) else {
            return ""
        }
        do {
            let html = try String(contentsOf: url)
            let stringData = parseReturnString(html: html)
            return stringData
        } catch {
            print("Error fetching HTML: \(error)")
        }
        return ""
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
    
    func getRecords(_ html: String) -> [String: String] {
        let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
        var result: [String: String] = [:]
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                return [:]
            }
            let content = try body.getElementById("dm_content")
            let links = try content?.getElementsByClass("showresults").select("a")
            try links?.forEach({ l in
                result[try l.text()] = try leadingLink + l.attr("href")
            })
        }
        catch {
            print("Parsing records failed")
        }
        return result
    }
}

struct ParsedView: View {
    @State private var urlString = ""
    @StateObject private var parser = HTMLParser()
    
    var body: some View {
        VStack {
            TextField("Enter URL", text: $urlString)
                .padding()
            
            Button("Parse HTML") {
                Task {
                    await parser.parse(urlString: urlString)
                    print(parser.myData)
                }
            }
            .padding()
            
            List(parser.myData, id: \.self) { rowData in
                HStack {
                    ForEach(rowData, id: \.self) { item in
                        Text(item)
                            .padding(5)
                            .border(Color.gray)
                    }
                }
            }
        }
        .padding()
    }
}
