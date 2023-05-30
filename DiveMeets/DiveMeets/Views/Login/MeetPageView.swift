//
//  MeetPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//  Revised for Meet Info/Results page on 5/28/23.
//

import SwiftUI

struct MeetPageView: View {
    @State private var meetData: MeetPageData?
    // Only meetEventData OR meetResultsEventData should be nil at a time (event is nil when passed
    //     a results link, and resultsEvent is nil when passed an info link)
    @State private var meetEventData: MeetEventData?
    @State private var meetResultsEventData: MeetResultsEventData?
    @State private var meetDiverData: MeetDiverData?
    @State private var meetCoachData: MeetCoachData?
    @State private var meetInfoData: MeetInfoJointData?
    @ObservedObject private var mpp: MeetPageParser = MeetPageParser()
    @State private var meetDetailsExpanded: Bool = false
    @State private var warmupDetailsExpanded: Bool = false
    private let getTextModel = GetTextAsyncModel()
    var meetLink: String
    
    private func tupleToList(data: MeetEventData) -> [[String]] {
        var result: [[String]] = []
        for event in data {
            let date = event.0
            let number = String(event.1)
            let name = event.2
            let rule = event.3
            let entries = String(event.4)
            result.append([date, number, name, rule, entries])
        }
        
        return result
    }
    
    private func tupleToList(data: MeetResultsEventData) -> [[String]] {
        var result: [[String]] = []
        for event in data {
            let name = event.0
            let link = event.1
            let entries = String(event.2)
            let date = event.3
            result.append([name, link, entries, date])
        }
        
        return result
    }
    
    private func tupleToList(data: MeetDiverData) -> [[String]] {
        var result: [[String]] = []
        for diver in data {
            let name = diver.0
            let team = diver.1
            let link = diver.2
            
            var row = [name, team, link]
            for d in diver.3 {
                row.append(d)
            }
            
            result.append(row)
        }
        
        return result
    }
    
    private func tupleToList(data: MeetCoachData) -> [[String]] {
        var result: [[String]] = []
        
        for coach in data {
            result.append([coach.0, coach.1, coach.2])
        }
        
        return result
    }
    
    private func tupleToList(data: MeetInfoData) -> [[String]] {
        var result: [[String]] = []
        
        for (key, value) in data {
            result.append([key, value])
        }
        
        return result
    }
    
    private func tupleToList(data: MeetInfoTimeData) -> [[String]] {
        var result: [[String]] = []
        
        for (date, times) in data {
            var row = [date]
            for (key, time) in times {
                row.append(key)
                row.append(time)
            }
            
            result.append(row)
        }
        
        return result
    }
    
    private func tupleToList(data: MeetInfoJointData) -> [[String]] {
        return tupleToList(data: data.0) + tupleToList(data: data.1)
    }
    
    private func keyToHStack(data: [String: String], key: String) -> HStack<TupleView<(Text, Text)>> {
        return HStack {
            Text("\(key): ")
                .bold()
            Text(data[key]!)
        }
    }
    
    private func dateSorted(
        _ time: MeetInfoTimeData) -> [(key: String, value: Dictionary<String, String>)] {
        let data = time.sorted(by: {
            let df = DateFormatter()
            df.dateFormat = "EEEE, MMM dd, yyyy"
            
            let d1 = df.date(from: $0.key)
            let d2 = df.date(from: $1.key)
            
            return d1! < d2!
        })
        
        return data
    }
    
    private func groupByDay(data: MeetEventData) -> [String: MeetEventData] {
        var result: [String: MeetEventData] = [:]
        
        for e in data {
            let date = e.0
            if !result.keys.contains(date) {
                result[date] = []
            }
            
            result[date]!.append(e)
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            if meetInfoData != nil {
                let info = meetInfoData!.0
                let time = meetInfoData!.1
                VStack(alignment: .leading, spacing: 10) {
                    Text(info["Name"]!)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(info["Sponsor"]!)
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(info["Start Date"]! + " - " + info["End Date"]!)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.trailing)
                    HStack {
                        Text("Signup Deadline: ")
                            .font(.headline)
                        Text(info["Online Signup Closes at"]!)
                            .multilineTextAlignment(.trailing)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Divider()
                    
                    DisclosureGroup(
                        isExpanded: $meetDetailsExpanded,
                        content: {
                            VStack(alignment: .leading, spacing: 10) {
                                keyToHStack(data: info, key: "Time Left Before Late Fee")
                                keyToHStack(data: info, key: "Type")
                                keyToHStack(data: info, key: "Rules")
                                keyToHStack(data: info, key: "Sponsor")
                                keyToHStack(data: info, key: "Pool")
                                keyToHStack(data: info, key: "Fee per event")
                                keyToHStack(data: info, key: "USA Diving Per Event Insurance Surcharge Fee")
                                keyToHStack(data: info, key: "Late Fee")
                                keyToHStack(data: info, key: "Fee must be paid by")
                                    .multilineTextAlignment(.trailing)
                                keyToHStack(data: info, key: "Warm up time prior to event")
                            }
                        },
                        label: {
                            Text("Meet Details")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                    )
                    .padding([.leading, .trailing])
                    
                    Divider()
                    
                    DisclosureGroup(
                        isExpanded: $warmupDetailsExpanded,
                        content: {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(dateSorted(time), id: \.key) { key, value in
                                    Text(key)
                                        .bold()
                                    VStack(alignment: .leading) {
                                        keyToHStack(data: value, key: "Warmup Starts")
                                        keyToHStack(data: value, key: "Warmup Ends")
                                        keyToHStack(data: value, key: "Events Start")
                                    }
                                    .padding(.leading, 30)
                                }
                            }
                        },
                        label: {
                            Text("Warmup Details")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                    )
                    .padding([.leading, .trailing])
                    
                    Divider()
                    
//                    List {
//
//                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            Task {
                // Initialize meet parse from index page
                let url = URL(string: meetLink)!
                
                // This sets getTextModel's text field equal to the HTML from url
                await getTextModel.fetchText(url: url)
                
                if let html = getTextModel.text {
                    meetData = try await mpp.parseMeetPage(link: meetLink, html: html)
                    if meetData != nil {
                        meetEventData = await mpp.getEventData(data: meetData!)
                        meetResultsEventData = mpp.getResultsEventData(data: meetData!)
                        meetDiverData = mpp.getDiverListData(data: meetData!)
                        meetCoachData = mpp.getCoachListData(data: meetData!)
                        meetInfoData = mpp.getMeetInfoData(data: meetData!)
                        print(meetEventData!)
                    }
                }
            }
        }
    }
}
