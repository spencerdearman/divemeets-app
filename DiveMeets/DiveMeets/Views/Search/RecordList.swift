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
    private let animation: Animation = .spring(response: 0.6, dampingFraction: 0.9)
    @ScaledMetric private var viewPadding: CGFloat = 58
    
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
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 30)
                                            .foregroundColor(rowColor)
                                            .matchedGeometryEffect(id: "rect", in: namespace)
                                            .frame(height: 0)
                                        HStack {
                                            Text(key)
                                                .foregroundColor(textColor)
                                                .font(.title3)
                                                .padding()
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(Color.gray)
                                                .padding()
                                        }
                                        .background(rowColor)
                                        .cornerRadius(cornerRadius)
                                    }
                                    .padding([.leading, .trailing])
                                    .matchedGeometryEffect(id: "row", in: namespace)
                                    .onTapGesture {
                                        withAnimation(animation) {
                                            result = value
                                            resultSelected = true
                                        }
                                    }
                                }
                            }
                            .padding()
                            .onAppear {
                                resultSelected = false
                            }
                        }
                    }
                } else if result != "" {
                    NavigationView {
                        GeometryReader { g in
                            ZStack {
                                RoundedRectangle(cornerRadius: 30)
                                    .foregroundColor(rowColor)
                                    .matchedGeometryEffect(id: "rect", in: namespace)
                                    .frame(height: g.size.height + 50)
                                ZStack(alignment: .topLeading) {
                                    ProfileView(profileLink: result)
                                        .matchedGeometryEffect(id: "row", in: namespace)
                                    Button(action: {
                                        withAnimation(animation) {
                                            resultSelected = false
                                            result = ""
                                        }
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 22))
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, viewPadding)
    }
}

struct NewRecordView: View {
    @Environment(\.colorScheme) var currentMode
    @Binding var resultSelected: Bool
    @Binding var result: String
    @Namespace var namespace
    
    var key: String
    var value: String
    
    private let cornerRadius: CGFloat = 30
    private let textColor: Color = Color.primary
    private let animation: Animation = .spring(response: 0.6, dampingFraction: 0.9)
    
    private var rowColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
//    @State private var show = false
    
    var body: some View {
//        if !show {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .foregroundColor(rowColor)
                    .matchedGeometryEffect(id: "rect", in: namespace)
                    .frame(height: 0)
                    HStack {
                        Text(key)
                            .foregroundColor(textColor)
                            .font(.title3)
                            .padding()
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.gray)
                            .padding()
                    }
                    .background(rowColor)
                    .cornerRadius(cornerRadius)
//                    .onDisappear {
//                        resultSelected = true
//                    }
//                    .onAppear {
//                        resultSelected = false
//                    }
                }
                .padding([.leading, .trailing])
                .matchedGeometryEffect(id: "row", in: namespace)
                .onTapGesture {
                    withAnimation(animation) {
                        result = value
                        resultSelected = true
                    }
                }
                
//        } else {
//            GeometryReader { g in
//                ZStack {
//                    RoundedRectangle(cornerRadius: 30)
//                        .foregroundColor(rowColor)
//                        .matchedGeometryEffect(id: "rect", in: namespace)
//                        .frame(height: g.size.height + 50)
//                    ZStack(alignment: .topLeading) {
//                        ProfileView(profileLink: value)
//                        .matchedGeometryEffect(id: "row", in: namespace)
//                        Button(action: {
//                            withAnimation(animation) {
//                                resultSelected = false
//                            }
//                        }) {
//                            Image(systemName: "chevron.left")
//                                .font(.system(size: 22))
//                        }
//                        .padding()
//                    }
//                }
//            }
//        }
    }
}

struct OldRecordView: View {
    @Environment(\.colorScheme) var currentMode
    @Binding var resultSelected: Bool
    
    var key: String
    var value: String
    
    private let cornerRadius: CGFloat = 30
    private let textColor: Color = Color.primary
    
    private var rowColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    
    var body: some View {
        NavigationLink(destination: ProfileView(profileLink: value)) {
            HStack {
                Text(key)
                    .foregroundColor(textColor)
                    .font(.title3)
                    .padding()
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.gray)
                    .padding()
            }
            .background(rowColor)
            .cornerRadius(cornerRadius)
            .onDisappear {
                resultSelected = true
            }
            .onAppear {
                resultSelected = false
            }
        }
        .padding([.leading, .trailing])
    }
}
