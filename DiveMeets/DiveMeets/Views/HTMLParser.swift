//
//  HTMLParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 3/14/23.
//

import SwiftUI
import SwiftSoup

final class HTMLParser: ObservableObject {
    @Published var myData = [Array<String>]()
    
    func parse(html: String) -> [Array<String>] {
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                return [[]]
            }
            let main = try body.getElementsByTag("body").compactMap({try? $0.html()})
            let html = main[0]
            let doc: Document = try SwiftSoup.parse(html)

            var myData = [Array<String>]()
            let myRows: Elements? = try doc.getElementsByTag("tr")
            try myRows?.forEach({ row in
                let tempString = try row.text()
                let split = tempString.components(separatedBy: "  ")
                myData.append(split)
            })
            myData[0] = myData[0][0].components(separatedBy: "History")
            myData[0].remove(at: 1)
            return myData
        }
        catch {
            print("Error Parsing: " + String(describing: error))
        }
        
        return myData
    }
    
    func parse(urlString: String) -> [Array<String>] {
        print(urlString)
        guard let url = URL(string: urlString) else {
            return []
        }
        
        do {
            let html = try String(contentsOf: url)
            myData = parse(html: html)
            return myData
        } catch {
            print("Error fetching HTML: \(error)")
        }
        return []
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
                parser.parse(urlString: urlString)
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

struct HTMLParser_Previews: PreviewProvider {
    static var previews: some View {
        ParsedView()
    }
}
