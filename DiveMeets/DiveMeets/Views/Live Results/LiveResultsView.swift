//
//  LiveResultsView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/8/23.
//

import SwiftUI

struct LiveResultsView: View {
    @State var request: String =
    "https://secure.meetcontrol.com/divemeets/system/livestats.php?event=stats-8960-180-9-Finished"
    @State var html: String = ""
    @State var rows: [[String: String]] = []
    @State var columns: [String] = []
    var body: some View {
        ZStack {
            LRWebView(request: $request, html: $html)
            Color.white.ignoresSafeArea()
            VStack {
                Divider()
                HStack {
                    ForEach(columns, id: \.self) { col in
                        Text(col)
                        Divider()
                    }
                }
                .frame(height: 50)
                Divider()
                ForEach(rows, id: \.self) { row in
                    HStack {
                        ForEach(columns, id: \.self) {key in
                            Text(row[key]!)
                            Divider()
                        }
                    }
                    .frame(height: 50)
                    Divider()
                }
            }
        }
        // Test parsing finished live results in this view
        .onChange(of: html) { newValue in
            var result: LiveResults = LiveResults(meetName: "Test",
                                                  eventName: "Test Event",
                                                  link: request,
                                                  isFinished: true)

            do {
                let document: Document = try SwiftSoup.parse(newValue)
                guard let body = document.body() else {
                    return
                }
                let table = try body.getElementById("Results")
                let rows = try table?.getElementsByTag("tr")

                let columnsRow = rows![2]
                for r in columnsRow.children() {
                    columns.append(try r.text())
                }

                for (idx, row) in rows!.enumerated() {
                    if idx < 3 || idx == rows!.count - 1 {
                        continue
                    }
                    var rowVals: [String] = []
                    let children = row.children()
                    for child in children {
                        rowVals.append(try child.text())
                    }

                    result.rows.append(Dictionary(uniqueKeysWithValues: zip(columns, rowVals)))
                }

                self.rows = result.rows
            
            } catch  {
                print("Parsing finished live event failed")
            }
        }
    }
}

struct LiveResultsView_Previews: PreviewProvider {
    static var previews: some View {
        LiveResultsView()
    }
}
