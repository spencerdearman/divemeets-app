//
//  RecordList.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct RecordList: View {
    @Environment(\.colorScheme) var currentMode
    @Binding var records: [String: String]
    @Binding var resultSelected: Bool
    
    // Style adjustments for elements of list
    private let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 3
    private let textColor: Color = Color.primary
    @ScaledMetric private var viewPadding: CGFloat = 58
    
    private var rowColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    
    private var customGray: Color {
        let gray = currentMode == .light ? 0.95 : 0.1
        return Color(red: gray, green: gray, blue: gray)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color for View
                customGray.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: rowSpacing) {
                        ForEach(records.sorted(by: <), id: \.key) { key, value in
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
                                        .onAppear{
                                            resultSelected = false
                                        }
                                    }
                                    .padding([.leading, .trailing])
                        }
                    }
                    .padding()
                }
                .navigationTitle("Results")
                .padding(.bottom, viewPadding)
            }
        }
    }
}

struct RecordList_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            RecordList(records: .constant(["Logan": "google.com"]),
                       resultSelected: .constant(false))
                .preferredColorScheme($0)
        }
    }
}
