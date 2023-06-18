//
//  Event.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/5/23.
//

import SwiftUI

struct Event: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isFirstNav: Bool
    @Binding var meet: MeetEvent
    @State var diverData : (String, String, String, Double, Double, Double, String) = ("", "", "", 0.0, 0.0, 0.0, "")
    @State var diverTableData: [Int: (String, String, String, Double, Double, Double, String)] = [:]
    @State var scoreDictionary: [String: String] = [:]
    @State var scoreData : [Int: Double] = [:]
    @State var isExpanded: Bool = false
    @State var expandedIndices: Set<Int> = []
    @State var scoreString: String = ""
    @State var fullEventPageShown: Bool = false
    
    @StateObject private var parser = EventHTMLParser()
    @StateObject private var scoreParser = ScoreHTMLParser()
    
    var body: some View {
        ZStack{}
            .onAppear {
                Task {
                    if let link = meet.link {
                        await parser.eventParse(urlString: link)
                        diverData = parser.eventData
                        await parser.tableDataParse(urlString: link)
                        diverTableData = parser.diveTableData
                    }
                }
            }
        NavigationView{
            VStack {
                if isFirstNav{
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
                }
                
                ForEach(diverTableData.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    ZStack{}
                        .onAppear{
                            Task {
                                await scoreParser.parse(urlString: value.6)
                                scoreData = scoreParser.scoreData
                                let sorted = scoreData.sorted { $0.key < $1.key }
                                let formatted = scoreData.map { " \($0.value) "  }.joined(separator:" | ")
                                scoreString = "| \(formatted) |"
                                scoreDictionary[value.0] = scoreString
                            }
                        }
                    
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(meet.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    Divider()
                    Text("Dates: " + diverData.1)
                    Text("Organization: " + diverData.2)
                    Divider()
                    Text("Total Score: " + String(diverData.5))
                        .font(.title3)
                        .bold()
                    HStack{
                        Text("Total Net Score: " + String(diverData.3))
                        Text("Total DD: " + String(diverData.4))
                    }
                    Divider()
                    if meet.firstNavigation && !fullEventPageShown {
                        NavigationLink (destination: {
                            EventResultPage(meetLink: diverData.6)
                        }, label: {
                            Text("Full Event Page")
                        })
                    }
                    
                    
                    List {
                        ForEach(diverTableData.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            DisclosureGroup(
                                isExpanded: isExpanded(key),
                                content: {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Height: \(value.1)")
                                        Text("Scores: " + (scoreDictionary[value.0] ?? ""))
                                        Text("Name: \(value.2)")
                                        Text("Net Score: \(value.3, specifier: "%.2f")")
                                        Text("DD: \(value.4, specifier: "%.1f")")
                                    }
                                    .padding(.leading, 20)
                                },
                                label: {
                                    Text(value.0 + " - " + String(value.5))
                                        .font(.headline)
                                }
                            )
                        }
                    }
                    .frame(height: 500)
                    .ignoresSafeArea()
                }
                .padding()
            }
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
