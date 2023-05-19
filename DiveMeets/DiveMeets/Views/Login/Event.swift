//
//  Event.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/5/23.
//

import SwiftUI

struct Event: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var meet: MeetEvent
    @State var diverData : (String, String, String, Double, Double, Double) = ("", "", "", 0.0, 0.0, 0.0)
    @State var diverTableData: [Int: (String, String, String, Double, Double, Double, String)] = [:]
    @State var scoreData : [Int: Double] = [:]
    @State var isExpanded: Bool = false
    @State var expandedIndices: Set<Int> = []
    
    @StateObject private var parser = EventHTMLParser()
    @StateObject private var scoreParser = ScoreHTMLParser()
    
    var body: some View {
        ZStack{}
            .onAppear {
                Task {
                    await parser.eventParse(urlString: meet.link!)
                    diverData = parser.eventData
                    await parser.tableDataParse(urlString: meet.link!)
                    diverTableData = parser.diveTableData
                    //print(diverTableData)
                    await scoreParser.parse(urlString: "https://secure.meetcontrol.com/divemeets/system/judgesscoresext.php?meetnum=8698&eventnum=7180&dvrnum=51197&divord=1&eventtype=9&synchdvrnum=&sts=1674154171")
                    scoreData = scoreParser.scoreData
                }
            }
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                Text(meet.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                List {
                    ForEach(diverTableData.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        DisclosureGroup(
                            isExpanded: isExpanded(key),
                            content: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Height: \(value.1)")
                                    Text("Name: \(value.2)")
                                    Text("Net Score: \(value.3)")
                                    Text("DD: \(value.4)")
                                    Text("Total Score: \(value.5)")
                                }
                                .padding(.leading, 20)
                            },
                            label: {
                                Text(value.0)
                                    .font(.headline)
                            }
                        )
                    }
                }
                .padding()
            }
            .padding()
        }
    }
    
    private func isExpanded(_ index: Int) -> Binding<Bool> {
        Binding(
            get: { expandedIndices.contains(index) },
            set: { isExpanded in
                if isExpanded {
                    expandedIndices.insert(index)
                } else {
                    expandedIndices.remove(index)
                }
            }
        )
    }
}

