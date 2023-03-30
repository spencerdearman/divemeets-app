//
//  ProfileParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/29/23.
//

import SwiftUI
import SwiftSoup

typealias DivingDict = [String: [String: [String: String]]]
typealias CoachingDict = [String: [String: String]]
typealias JudgingDict = [String]
typealias DiverList = [(String, String)]

private enum Stage {
    case diving
    case coaching
    case judging
    case diverList
    case notSet
}

final class ProfileParser: ObservableObject {
    
    private func wrapLooseText(text: String) -> String {
        do {
            var result: String = text
            let minStringLen = "&nbsp;&nbsp;Coach:".count
            let pattern = "<br>[a-zA-z0-9\\s&;:]+"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsrange = NSRange(text.startIndex..<text.endIndex,
                                  in: text)
            var seen: Set<Substring> = Set<Substring>()
            regex.enumerateMatches(in: text, range: nsrange) {
                (match, _, _) in
                guard let match = match else { return }
                
                
                for i in 0..<match.numberOfRanges {
                    let m = text[Range(match.range(at: i), in: text)!]
                    if m.count >= minStringLen {
                        if seen.contains(m) {
                            continue
                        }
                        result = result.replacingOccurrences(of: m, with: "<div>" + m + "</div>")
                        seen.insert(m)
                    }
                }
            }
            
            return result
        } catch {
            print("Failed to parse text input")
        }
        
        return ""
    }

    private func isHeader(_ elem: Element) -> Bool {
        let headers: Set<String> = Set<String>(["Diving:", "Coaching:", "Judging:"])
        do {
            return try elem.tagName() == "strong" && headers.contains(elem.text())
        } catch {
            return false
        }
    }
    
    private func getStage(_ elem: Element) -> Stage? {
        if !isHeader(elem) {
            return nil
        }
        do {
            switch try elem.text() {
                case "Diving:":
                    return .diving
                case "Coaching:":
                    return .coaching
                case "Judging:":
                    return .judging
                default:
                    return nil
            }
        } catch {
            print("Error getting element text")
        }
        
        return nil
    }
    
    func parseProfile(html: String) -> (DivingDict?, CoachingDict?, JudgingDict?, DiverList?) {
        var diving: DivingDict?
        var coaching: CoachingDict?
        var judging: JudgingDict?
        var diverList: DiverList?
        var stage: Stage = .notSet
        
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                return (nil, nil, nil, nil)
            }
            var foundHeader = false
            let rows = try body.getElementsByTag("td")
            let first = rows.first()!
            
            let doc: Document = try SwiftSoup.parseBodyFragment(wrapLooseText(text: try first.html()))
            guard let wrappedText = doc.body()?.children() else {
                return (nil, nil, nil, nil)
            }
            
            var keepRows: [Element] = []
            for r in wrappedText {
                let tag = r.tagName()
                if tag == "table" {
                    break
                } else if tag == "br" || tag == "img" || tag == "span" {
                    continue
                } else {
                    keepRows.append(r)
                }
            }
            
            for r in keepRows {
                let tag = r.tagName()
                if !foundHeader && isHeader(r) {
                    foundHeader = true
                    stage = getStage(r)!
                }
                else if !foundHeader {
                    continue
                }
                
                print(tag)
                switch tag {
                    case "center":
                        stage = .diverList
                    case "div", "strong":
                        print(try r.text().trimmingCharacters(in: .whitespacesAndNewlines))
                    case "a":
                        var link = try r.attr("href")
                        let delIndex = link.index(link.startIndex, offsetBy: 7)
                        link = "https://secure.meetcontrol.com/divemeets/system/" +
                        link.replacingCharacters(in: delIndex...delIndex, with: "")
                        let tuple = (try r.text(), link)
                        print(tuple)
                        if stage == .diverList {
                            if diverList == nil {
                                diverList = []
                            }
                            diverList?.append(tuple)
                        }
                    default:
                        continue
                }
                print("-------------------")
            }
        } catch {
            print("Error parsing profile")
        }
        
        return (diving, coaching, judging, diverList)
    }
}

struct ProfileParserView: View {
    var text: String = ""
    let p: ProfileParser = ProfileParser()
    var body: some View {
        
        Button("Button") {
            let session = URLSession.shared
            let url = URL(string: "https://secure.meetcontrol.com/divemeets/system/profile.php?number=20617")!
            var diving: DivingDict?
            var coaching: CoachingDict?
            var judging: JudgingDict?
            var diverList: DiverList?
            let task = session.dataTask(with: url) { data, response, error in
                // Check whether data is not nil
                guard let loadedData = data else { return }
                // Load HTML code as string
                let text = String(data: loadedData, encoding: .utf8)
                
                (diving, coaching, judging, diverList) = p.parseProfile(html: text!)
                print(diving ?? [:], coaching ?? [:], judging ?? [], diverList ?? [])
            }
            task.resume()
            
        }
    }
    
}
