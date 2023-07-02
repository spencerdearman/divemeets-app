//
//  MeetScoreCalculator.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 7/1/23.
//

import SwiftUI

enum MeetType: String, CaseIterable {
    case one = "1M"
    case three = "3M"
    case platform = "Platform"
}

enum DiveHeight: String, CaseIterable {
    case five = "5M"
    case seven = "7.5M"
    case ten = "10M"
}

// If providing dives list, also need to provide numDives so it doesn't clear dives list on appear
struct MeetScoreCalculator: View {
    @State var tableData: [String: DiveData]?
    @State var numDives: Int = 2
    @State var meetType: MeetType = .one
    @State var dives: [String] = []
    @State var diveNetScores: [Double] = []
    @State var diveTotalScores: [Double] = []
    
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    private func clearDivesList() {
        dives = []
        diveNetScores = []
        diveTotalScores = []
        for _ in 0..<numDives {
            dives.append("")
            diveNetScores.append(0.0)
            diveTotalScores.append(0.0)
        }
    }
    
    private func setDivesList() {
        diveNetScores = []
        diveTotalScores = []
        for _ in 0..<numDives {
            if dives.count < numDives {
                dives.append("")
            }
            diveNetScores.append(0.0)
            diveTotalScores.append(0.0)
        }
    }
    
    private func refreshDives() {
        for idx in 0..<numDives {
            if idx >= dives.count {
                dives.append("")
            }
            if idx < diveNetScores.count {
                diveNetScores[idx] += 0.0
            } else {
                diveNetScores.append(0.0)
            }
            if idx < diveTotalScores.count {
                diveTotalScores[idx] = diveNetScores[idx] * 1.0
            } else {
                diveTotalScores.append(0.0)
            }
        }
    }
    
    var body: some View {
        VStack {
            Text("Meet Score Calculator")
                .font(.title)
                .bold()
            CalculatorTopView(tableData: $tableData, numDives: $numDives, meetType: $meetType,
                              dives: $dives)
            .onChange(of: numDives) { _ in
                refreshDives()
            }
            .onChange(of: meetType) { _ in
                refreshDives()
            }
            .onAppear {
                if dives.count > 0 {
                    numDives = dives.count
                }
                setDivesList()
                if dives.count > 0 {
                    refreshDives()
                }
            }
            
            let total = diveTotalScores.reduce(into: 0.0, { $0 += $1 })
            if total > 0.0 {
                HStack(spacing: 0) {
                    Text("Meet Total: ")
                        .bold()
                    Text(String(format: "%.2f", total))
                    
                }
                .font(.title2)
                
                Divider()
            }
            
            ScrollView(showsIndicators: false) {
                ForEach(0..<numDives, id: \.self) { i in
                    CalculatorRowView(tableData: $tableData, dives: $dives, meetType: $meetType,
                                      diveNetScores: $diveNetScores,
                                      diveTotalScores: $diveTotalScores, idx: i)
                    if i < numDives - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(.bottom, maxHeightOffset)
        .onAppear {
            tableData = getDiveTableData()
        }
    }
}

struct CalculatorTopView: View {
    @Binding var tableData: [String: DiveData]?
    @Binding var numDives: Int
    @Binding var meetType: MeetType
    @Binding var dives: [String]
    
    private let cornerRadius: CGFloat = 15
    private let lightGray = Color(red: 0.9, green: 0.9, blue: 0.9)
    private let selectedGray = Color(red: 0.85, green: 0.85, blue: 0.85)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(red: 0.9, green: 0.9, blue: 0.9))
            HStack(spacing: 0) {
                ForEach(MeetType.allCases, id: \.self) { m in
                    ZStack {
                        // Weird padding stuff to have end options rounded on the outside edge only
                        // when selected
                        // https://stackoverflow.com/a/72435691/22068672
                        Rectangle()
                            .fill(meetType == m ? selectedGray : lightGray)
                            .padding(.trailing, m == MeetType.allCases.first ? cornerRadius : 0)
                            .padding(.leading, m == MeetType.allCases.last ? cornerRadius : 0)
                            .cornerRadius(m == MeetType.allCases.first || m == MeetType.allCases.last
                                          ? cornerRadius : 0)
                            .padding(.trailing, m == MeetType.allCases.first ? -cornerRadius : 0)
                            .padding(.leading, m == MeetType.allCases.last ? -cornerRadius : 0)
                        Text(m.rawValue)
                    }
                    .onTapGesture {
                        meetType = m
                    }
                    if m != MeetType.allCases.last {
                        Divider()
                    }
                }
            }
        }
        .frame(height: 50)
        .padding([.leading, .trailing])
        
        HStack {
            Text("Number of Dives:")
            Picker("", selection: $numDives) {
                ForEach(0...11, id: \.self) { i in
                    Text(String(i))
                        .tag(i)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100, height: 80)
        }
        .padding([.leading, .trailing, .bottom])
    }
}

struct CalculatorRowView: View {
    @State var diveHeight: DiveHeight = .five
    @State var judgeScores: [Int] = [10, 10, 10]
    @State var scoreValues: [Double] = Array(stride(from: 0.0, to: 10.5, by: 0.5))
    @Binding var tableData: [String: DiveData]?
    @Binding var dives: [String]
    @Binding var meetType: MeetType
    @Binding var diveNetScores: [Double]
    @Binding var diveTotalScores: [Double]
    let idx: Int
    
    @ScaledMetric var wheelPickerSelectedSpacing: CGFloat = 40
    
    private var meetTypeDouble: Double? {
        if meetType == .one {
            return 1.0
        } else if meetType == .three {
            return 3.0
        }
        
        return nil
    }
    
    private var diveName: String {
        if idx < dives.count {
            return getDiveName(data: tableData ?? [:],
                               forKey: $dives[idx].wrappedValue) ?? ""
        }
        
        return ""
    }
    
    private var dd: Double {
        if idx < dives.count {
            return getDiveDD(data: tableData ?? [:], forKey: $dives[idx].wrappedValue,
                             height: meetTypeDouble == nil
                             ? Double(String(diveHeight.rawValue.dropLast())) ?? 0.0
                             : meetTypeDouble!) ?? 0.0
        }
        
        return 0.0
    }
    
    private func updateNetAndTotalScores() {
        if idx < diveNetScores.count {
            diveNetScores[idx] = judgeScores.reduce(into: 0.0, { $0 += scoreValues[$1] })
        }
        if idx < diveTotalScores.count {
            diveTotalScores[idx] = diveNetScores[idx] * dd
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                if idx < dives.count {
                    TextField("Number", text: $dives[idx])
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .frame(width: 80)
                }
                Divider()
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 5) {
                        Text("Name:")
                            .fontWeight(.semibold)
                        
                        // Only shows name if there is an associated DD, otherwise show N/A
                        dd == 0.0 ? Text("N/A") : Text(diveName)
                    }
                    
                    if meetType == .platform {
                        HStack(spacing: 0) {
                            Text("Height: ")
                                .fontWeight(.semibold)
                            Picker("", selection: $diveHeight) {
                                ForEach(DiveHeight.allCases, id: \.self) { h in
                                    Text(h.rawValue)
                                        .tag(h)
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    
                    HStack(spacing: 0) {
                        Text("DD: ")
                            .fontWeight(.semibold)
                        // Shows N/A if there is not an associated dd with that height
                        Text(dd == 0.0 ? "N/A" : String(dd))
                    }
                }
                
                Spacer()
            }
            ForEach(0..<3) { i in
                HStack {
                    Text("Judge \(i+1):")
                        .fontWeight(.semibold)
                    SwiftUIWheelPicker($judgeScores[i], items: scoreValues) { value in
                        GeometryReader { g in
                            Text(String(format: "%.1f", value))
                                .frame(width: g.size.width, height: g.size.height,
                                       alignment: .center)
                        }
                    }
                    .scrollAlpha(0.1)
                    .centerView(AnyView(
                        HStack(alignment: .center, spacing: 0) {
                            Divider()
                                .frame(width: 1)
                                .background(Color.gray)
                                .opacity(0.4)
                            Spacer()
                            Divider()
                                .frame(width: 1)
                                .background(Color.gray)
                                .opacity(0.4)
                        }
                    ), width: .Fixed(wheelPickerSelectedSpacing))
                    .onChange(of: judgeScores[i]) { _ in
                        updateNetAndTotalScores()
                    }
                    .onChange(of: dives) { _ in
                        updateNetAndTotalScores()
                    }
                    .onChange(of: meetType) { _ in
                        updateNetAndTotalScores()
                    }
                    .onChange(of: diveNetScores) { _ in
                        updateNetAndTotalScores()
                    }
                    .onAppear {
                        print(diveNetScores)
                        updateNetAndTotalScores()
                    }
                }
            }
            
            if idx < diveNetScores.count && diveNetScores[idx] != 0.0 {
                HStack(spacing: 0) {
                    Spacer()
                    Text("Net Score: ")
                        .fontWeight(.semibold)
                    Text(String(diveNetScores[idx]))
                }
                .padding(.top)
                HStack(spacing: 0) {
                    Spacer()
                    Text("Total Score: ")
                        .fontWeight(.semibold)
                    Text(String(format: "%.2f", diveTotalScores[idx]))
                }
            }
        }
        .padding()
    }
}
