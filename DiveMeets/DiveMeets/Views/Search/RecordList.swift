//
//  RecordList.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct RecordList: View {
    @Environment(\.colorScheme) var currentMode
    @Binding var records: DiverProfileRecords
    @Binding var resultSelected: Bool
    @Binding var fullScreenResults: Bool
    @State var result: String = ""
    @Namespace var namespace
    
    // Style adjustments for elements of list
    private let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 3
    private let textColor: Color = Color.primary
    private let animationSpeed: CGFloat = 0.5
    @ScaledMetric private var viewPadding: CGFloat = 58
    
    private var animation: Animation {
        Animation.spring(response: animationSpeed,
                         dampingFraction: 0.9)
    }
    
    private var rowColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    
    private var customGray: Color {
        let gray = currentMode == .light ? 0.95 : 0.1
        return Color(red: gray, green: gray, blue: gray)
    }

    // Converts keys and lists of values into tuples of key and value
    private func getSortedRecords(_ records: DiverProfileRecords) -> [(String, String)] {
        var result: [(String, String)] = []
        for (key, value) in records {
            for link in value {
                result.append((key, link))
            }
        }
        
        return result.sorted(by: { $0.0 < $1.0 })
    }
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                // Background color for View
                customGray.ignoresSafeArea()
                
                if !resultSelected {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Results")
                            .font(.largeTitle)
                            .bold()
                            .padding(.leading, 20)
                            .padding(.top, 50)
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: rowSpacing) {
                                ForEach(records.sorted(by: <), id: \.key) { key, value in
                                    RecordView(resultSelected: $resultSelected, result: $result,
                                               key: key, value: value, namespace: namespace,
                                               animationSpeed: animationSpeed)
                                }
                            }
                            .padding()
                            .onAppear {
                                resultSelected = false
                                result = ""
                            }
                        }
                    }
                } else {
                    ExpandedRecordView(resultSelected: $resultSelected, result: $result, proxy: g,
                                       namespace: namespace, animationSpeed: animationSpeed)
                }
            }
        }
        .padding(.bottom, viewPadding)
    }
}
