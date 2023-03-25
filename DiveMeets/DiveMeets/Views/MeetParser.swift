//
//  MeetParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/22/23.
//

import SwiftUI
import SwiftSoup

final class MeetParser: ObservableObject {
    
    func parse(html: String) -> String {
//    func parse(html: String) -> ([String: String], [String: String]) {
        var upcomingMeets: [String: String] = [:]
        var pastMeets: [String: String] = [:]
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                return "hello"
            }
            let menu = try body.getElementById("dm_menu_centered")
            let menuTabs = try menu?.getElementsByTag("ul")
            print("--------------------MenuTabs!----------------")
            for tab in menuTabs! {
                print(tab)
                print("\n")
            }
//            print(menuTabs!)
            print("---------------------------------------------")
            
        } catch {
            print("Error parsing meets")
        }
        
        return "Hello World"
//        return (upcomingMeets, pastMeets)
    }
}

struct MeetParserView: View {
    var text: String = ""
    let p: MeetParser = MeetParser()
    var body: some View {
        
        Button("Button") {
            let session = URLSession.shared
            let url = URL(string: "https://secure.meetcontrol.com/divemeets/system/index.php")!
            let task = session.dataTask(with: url) { data, response, error in
                // Check whether data is not nil
                guard let loadedData = data else { return }
                // Load HTML code as string
                let text = String(data: loadedData, encoding: .utf8)
//                print(text!)
                p.parse(html: text!)
            }
            task.resume()
//            while text == "" {
//                ""
//            }
            
        }
    }
    
}

//struct MeetParserView_Previews: PreviewProvider {
//    static var previews: some View {
//        MeetParserView()
//    }
//}
