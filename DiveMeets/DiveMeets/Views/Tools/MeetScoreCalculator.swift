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

struct MeetScoreCalculator: View {
    @State var tableData: [String: DiveData]?
    @State var numDives: Int = 2
    @State var meetType: MeetType = .one
    @State var dives: [String] = []
    @State var diveNetScores: [Double] = []
    
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    private func updateDivesList() {
        dives = []
        diveNetScores = []
        for _ in 0..<numDives {
            dives.append("")
            diveNetScores.append(0.0)
        }
    }
    
    var body: some View {
        VStack {
            CalculatorTopView(tableData: $tableData, numDives: $numDives, meetType: $meetType,
                              dives: $dives)
            .onChange(of: numDives) { newValue in
                updateDivesList()
            }
            .onAppear {
                updateDivesList()
            }
            
            ScrollView(showsIndicators: false) {
                ForEach(0..<numDives, id: \.self) { i in
                    CalculatorRowView(tableData: $tableData, dives: $dives, meetType: $meetType,
                                      diveNetScores: $diveNetScores, idx: i)
                    //                        .frame(maxHeight: 100)
                    if i < numDives - 1 {
                        Divider()
                    }
                }
            }
            //            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            //            Spacer()
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
    
    var body: some View {
        HStack {
            Text("Meet Type:")
            Picker("", selection: $meetType) {
                ForEach(MeetType.allCases, id: \.self) { m in
                    Text(m.rawValue)
                        .tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 150, height: 80)
        }
        .padding([.leading, .trailing, .top])
        
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
    @State var scoreValues: [Double] = Array(stride(from: 0.0, to: 10.0, by: 0.5))
    @Binding var tableData: [String: DiveData]?
    @Binding var dives: [String]
    @Binding var meetType: MeetType
    @Binding var diveNetScores: [Double]
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
    
    var body: some View {
        VStack {
            HStack {
                if idx < $dives.count {
                    TextField("Number", text: $dives[idx])
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .frame(width: 100)
                    Divider()
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top, spacing: 5) {
                            Text("Name:")
                                .fontWeight(.semibold)
                            Text(getDiveName(data: tableData ?? [:],
                                                         forKey: $dives[idx].wrappedValue)
                                             ?? "")
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
                        
                        let dd = String(getDiveDD(data: tableData ?? [:],
                                                  forKey: $dives[idx].wrappedValue,
                                                  height: meetTypeDouble == nil
                                                  ? Double(String(diveHeight.rawValue.dropLast())) ?? 0.0
                                                  : meetTypeDouble!) ?? 0.0)
                        HStack(spacing: 0) {
                            Text("DD:")
                                .fontWeight(.semibold)
                            Text(dd == "0.0" ? "" : dd)
                        }
                    }
                } else {
                    Text("Failed at idx \(idx)")
                }
                Spacer()
            }
            VStack {
                ForEach(0..<3) { i in
                    HStack {
                        Text("Judge \(i+1):")
                            .fontWeight(.semibold)
                        SwiftUIWheelPicker($judgeScores[i], items: scoreValues) { value in
                            GeometryReader { g in
                                Text(String(format: "%.1f", value))
                                    .frame(width: g.size.width, height: g.size.height, alignment: .center)
                            }
                        }
                        .scrollAlpha(0.1)
                        .centerView(AnyView(
                            HStack(alignment: .center, spacing: 0) {
                                Divider()
                                    .frame(width: 1)
                                    .background(Color.gray)
//                                    .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                                    .opacity(0.4)
                                Spacer()
                                Divider()
                                    .frame(width: 1)
                                    .background(Color.gray)
//                                    .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                                    .opacity(0.4)
                            }
                        ), width: .Fixed(wheelPickerSelectedSpacing))
                    }
                }
            }
        }
        .padding()
        .onChange(of: judgeScores) { newValue in
            print(newValue)
        }
    }
}
