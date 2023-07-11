//
//  JudgeScoreCalculator.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 7/2/23.
//

import SwiftUI

enum JudgeScoreField: Int, Hashable, CaseIterable {
    case dive
    case score
}

struct JudgeScoreCalculator: View {
    @Environment(\.colorScheme) var currentMode
    @State var tableData: [String: DiveData]?
    @State var dive: String = ""
    @State var name: String?
    @State var dd: Double?
    @State var height: DiveHeight = .one
    @State var score: String = ""
    @State var judgesScores: [String] = []
    @FocusState var focusedField: JudgeScoreField?
    
    private var screenWidth = UIScreen.main.bounds.width
    private var screenHeight = UIScreen.main.bounds.height
    private let cornerRadius: CGFloat = 30
    private let shadowRadius: CGFloat = 5
    private let selectedGray = Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.4)
    
    private var heightDouble: Double {
        Double(String(height.rawValue.dropLast())) ?? 0.0
    }
    
    private var scoreDouble: Double? {
        if let res = Double(score) {
            return res
        }
        
        return nil
    }
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    private func computeJudgesScores() -> [String] {
        guard let total = scoreDouble else { return [] }
        guard let dd = dd else { return [] }
        let netRaw = total / dd
        let netInt = Double(Int(netRaw))
        let netRemainder = netRaw.truncatingRemainder(dividingBy: 1)
        let net: Double
        
        // Rounds up to nearest 0.5 so judge scores will always produce at least the desired score
        // total is evently divided by dd to nearest 0.5
        if netInt == netRaw || netRemainder == 0.5 {
            net = netRaw
            // total is between a whole and 0.5 on low end
        } else if netRemainder < 0.5 {
            net = netInt + 0.5
            // total is between a whole and 0.5 on high end
        } else {
            net = netInt + 1.0
        }
        
        let fractionalJudgeScore = net / 3.0
        let whole = Double(Int(fractionalJudgeScore))
        let wholePlusHalf = whole + 0.5
        let wholePlusOne = whole + 1.0
        let remainder = fractionalJudgeScore.truncatingRemainder(dividingBy: 1)
        var result: [Double] = []
        
        // Determines the judge scores required to sum to the net score
        if remainder == 0.0 || remainder == 0.5 {
            result = [fractionalJudgeScore, fractionalJudgeScore, fractionalJudgeScore]
        } else if remainder < 0.2 {
            result = [whole, whole, wholePlusHalf]
        } else if remainder < 0.4 {
            result = [whole, wholePlusHalf, wholePlusHalf]
        } else if remainder < 0.8 {
            result = [wholePlusHalf, wholePlusHalf, wholePlusOne]
        } else {
            result = [wholePlusHalf, wholePlusOne, wholePlusOne]
        }
        
        // Last value will always be >= other values, so if it exceeds 10.0, then score is too big
        if result.count > 2 && result.last! > 10.0 {
            return ["Not possible"]
        }
        
        return result.map { String($0) }
    }
    
    var body: some View {
        ZStack {
            Color.clear
            ZStack {
                Rectangle()
                    .foregroundColor(Custom.thinMaterialColor)
                    .mask(RoundedRectangle(cornerRadius: 50))
                    .frame(width: screenWidth * 0.9, height: screenHeight * 0.42)
                    .shadow(radius: shadowRadius)
                
                VStack(spacing: 5) {
                    
                    VStack(spacing: 20) {
                        Text("Judge Score Calculator")
                            .foregroundColor(.primary)
                            .font(.title2)
                            .bold()
                            .padding(.top, 30)
                        
                        DiveHeightSelectView(height: $height)
                            .scaleEffect(0.9)
                        
                        HStack {
                            Spacer()
                            TextField("Number", text: $dive)
                                .textInputAutocapitalization(.characters)
                                .focused($focusedField, equals: .dive)
                                .frame(width: 150, height: 50)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .background(RoundedRectangle(cornerRadius: cornerRadius).fill(.thinMaterial))
                                .onChange(of: dive) { _ in
                                    dive = String(dive.prefix(5))
                                }
                                .shadow(radius: shadowRadius)
                            Spacer()
                            TextField("Desired Score", text: $score)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .score)
                                .frame(width: 150, height: 50)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .background(RoundedRectangle(cornerRadius: cornerRadius).fill(.thinMaterial))
                                .shadow(radius: shadowRadius)
                                .onChange(of: score) { _ in
                                    score = String(score.prefix(6))
                                }
                            Spacer()
                        }
                        
                        VStack(spacing: 5) {
                            if name != nil {
                                HStack(spacing: 0) {
                                    Text("Name: ")
                                        .bold()
                                    Text(getDiveName(data: tableData ?? [:], forKey: $dive.wrappedValue) ?? "")
                                }
                            }
                            
                            if dd != nil {
                                HStack(spacing: 0) {
                                    Text("DD: ")
                                        .bold()
                                    Text(String((getDiveDD(data: tableData ?? [:], forKey: $dive.wrappedValue,
                                                           height: heightDouble) ?? 0.0)))
                                }
                            }
                        }
                        
                        if scoreDouble != nil {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(Custom.thinMaterialColor)
                                    .mask(RoundedRectangle(cornerRadius: 30))
                                    .frame(width: screenWidth * 0.5, height: screenHeight * 0.09)
                                    .shadow(radius: shadowRadius)
                                VStack(spacing: 5) {
                                    Text("Judges Scores")
                                        .bold()
                                        .underline()
                                    Text(judgesScores.joined(separator: " | "))
                                        .fontWeight(.semibold)
                                }
                                .font(.title2)
                            }
                        }
                    }
                    .onChange(of: dive) { newValue in
                        name = getDiveName(data: tableData ?? [:], forKey: newValue)
                        dd = getDiveDD(data: tableData ?? [:], forKey: newValue, height: heightDouble)
                        judgesScores = computeJudgesScores()
                    }
                    .onChange(of: height) { _ in
                        dd = getDiveDD(data: tableData ?? [:], forKey: dive, height: heightDouble)
                        judgesScores = computeJudgesScores()
                    }
                    .onChange(of: score) { _ in
                        judgesScores = computeJudgesScores()
                    }
                    .onAppear {
                        tableData = getDiveTableData()
                    }
                }
            }
        }
    }
    
    struct DiveHeightSelectView: View {
        @Binding var height: DiveHeight
        
        private let cornerRadius: CGFloat = 30
        private let selectedGray = Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.4)
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Custom.selectionColorsDark)
                    .shadow(radius: 10)
                HStack(spacing: 0) {
                    ForEach(DiveHeight.allCases, id: \.self) { h in
                        ZStack {
                            // Weird padding stuff to have end options rounded on the outside edge only
                            // when selected
                            // https://stackoverflow.com/a/72435691/22068672
                            Rectangle()
                                .fill(height == h ? selectedGray : .clear)
                                .padding(.trailing, h == DiveHeight.allCases.first ? cornerRadius : 0)
                                .padding(.leading, h == DiveHeight.allCases.last ? cornerRadius : 0)
                                .cornerRadius(h == DiveHeight.allCases.first || h == DiveHeight.allCases.last
                                              ? cornerRadius : 0)
                                .padding(.trailing, h == DiveHeight.allCases.first ? -cornerRadius : 0)
                                .padding(.leading, h == DiveHeight.allCases.last ? -cornerRadius : 0)
                            Text(h.rawValue)
                        }
                        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .onTapGesture {
                            height = h
                        }
                        if h != DiveHeight.allCases.last {
                            Divider()
                        }
                    }
                }
            }
            .frame(height: 50)
            .padding([.leading, .trailing])
        }
    }
}
