//
//  MeetPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//  Revised for Meet Info/Results page on 5/28/23.
//

import SwiftUI

struct MeetPageView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var meetData: MeetPageData?
    // Only meetEventData OR meetResultsEventData should be nil at a time (event is nil when passed
    //     a results link, and resultsEvent is nil when passed an info link)
    @State private var meetEventData: MeetEventData?
    @State private var meetResultsEventData: MeetResultsEventData?
    @State private var meetDiverData: MeetDiverData?
    @State private var meetCoachData: MeetCoachData?
    @State private var meetInfoData: MeetInfoJointData?
    @State private var meetResultsData: MeetResultsData?
    @ObservedObject private var mpp: MeetPageParser = MeetPageParser()
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
    
    private func formatAddress(_ addr: String) -> String {
        let idx = addr.firstIndex(where: { c in return c.isNumber })!
        var result = addr
        if result.distance(from: result.startIndex, to: idx) > 0 {
            result.insert("\n", at: idx)
        }
        return result
    }
    
    var body: some View {
        NavigationView {
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
                
                if meetInfoData != nil {
                    MeetInfoPageView(meetInfoData: meetInfoData!)
                    Spacer()
                } else if meetResultsData != nil {
                    MeetResultsPageView(meetResultsData: meetResultsData!)
                    Spacer()
                } else {
                    VStack {
                        Text("Getting meet information...")
                        ProgressView()
                    }
                }
            }
        }
        .onAppear {
            Task {
                // Initialize meet parse from index page
                let url = URL(string: meetLink)
                
                if let url = url {
                    // This sets getTextModel's text field equal to the HTML from url
                    await getTextModel.fetchText(url: url)
                    
                    if let html = getTextModel.text {
                        meetData = try await mpp.parseMeetPage(link: meetLink, html: html)
                        if let meetData = meetData {
//                            meetEventData = await mpp.getEventData(data: meetData)
//                            print(meetEventData != nil ? meetEventData : nil)
//                            meetResultsEventData = mpp.getResultsEventData(data: meetData)
//                            meetDiverData = mpp.getDiverListData(data: meetData)
//                            meetCoachData = mpp.getCoachListData(data: meetData)
                            meetInfoData = await mpp.getMeetInfoData(data: meetData)
                            meetResultsData = await mpp.getMeetResultsData(data: meetData)
                        }
                    }
                }
            }
        }
    }
}

struct MeetInfoPageView: View {
    var meetInfoData: MeetInfoJointData
    @State private var meetDetailsExpanded: Bool = false
    @State private var warmupDetailsExpanded: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertText: String = ""
    
    private func keyToHStack(data: [String: String],
                             key: String) -> HStack<TupleView<(Text, Text)>> {
        return HStack(alignment: .top) {
            Text("\(key): ")
                .bold()
            data[key] != nil ? Text(data[key]!) : Text("")
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
    
    
    var body: some View {
        let info = meetInfoData.0
        let time = meetInfoData.1
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
            
            Divider()
            
            DisclosureGroup(
                isExpanded: $meetDetailsExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            Text("Signup Deadline: ")
                                .bold()
                            Text(info["Online Signup Closes at"]!)
                                .multilineTextAlignment(.trailing)
                        }
                        keyToHStack(data: info, key: "Time Left Before Late Fee")
                        keyToHStack(data: info, key: "Type")
                        keyToHStack(data: info, key: "Rules")
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
                        .foregroundColor(Color.primary)
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
                        .foregroundColor(Color.primary)
                }
            )
            .padding([.leading, .trailing])
            
            Divider()
            
            if let meetEventData = meetInfoData.2 {
                MeetEventListView(showingAlert: $showingAlert, alertText: $alertText,
                                  meetEventData: meetEventData)
                .alert(alertText, isPresented: $showingAlert) {
                    Button("OK", role: .cancel) {
                        showingAlert = false
                        alertText = ""
                    }
                }
            }
        }
        .padding()
    }
}

struct MeetResultsPageView: View {
    var meetResultsData: MeetResultsData
    
    private func fixDateFormatting(_ str: String) -> String? {
        do {
            return try correctDateFormatting(str)
        } catch {
            print("Fixing date formatting failed")
        }
        
        return nil
    }
    
    var body: some View {
        let name = meetResultsData.0
        let date = meetResultsData.1
        let dates = date.components(separatedBy: " to ")
        let (startDate, endDate) = (fixDateFormatting(dates.first!) ?? "",
                                    fixDateFormatting(dates.last!) ?? "")
        let divers = meetResultsData.2
        let events = meetResultsData.3
        VStack(spacing: 10) {
            
            Text(name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(startDate + " - " + endDate)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.trailing)
            
            Divider()
            
            VStack {
                ForEach(events.indices, id: \.self) { index in
                    let event = events[index]
                    let name = event.0
                    let link = event.1
                    let entries = event.2
                    let date = event.3
                    HStack {
                        Text(name)
                        Spacer()
                        Text(String(entries))
                        Spacer()
                        Text(date)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            let name = meetResultsData.0
            let date = meetResultsData.1
            let divers = meetResultsData.2
            let events = meetResultsData.3
//            print(name)
//            print(date)
//            print(divers)
//            print(events)
        }
    }
}

struct MeetEventListView: View {
    @Binding var showingAlert: Bool
    @Binding var alertText: String
    var meetEventData: MeetEventData
    
    private func dateSorted(
        _ events: [String: MeetEventData]) -> [(key: String, value: MeetEventData)] {
            let data = events.sorted(by: {
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
        let data = dateSorted(groupByDay(data: meetEventData))
        List {
            ForEach(data, id: \.key) { key, value in
                Section {
                    ForEach(value.indices, id: \.self) { index in
                        HStack {
                            NavigationLink(value[index].2) {
                                EntryPageView()
                            }
                            Spacer()
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button("Rule") {
                                showingAlert = true
                                alertText = value[index].3
                            }
                            .tint(.blue)
                        }
                    }
                } header: {
                    Text(key)
                        .font(.subheadline)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
