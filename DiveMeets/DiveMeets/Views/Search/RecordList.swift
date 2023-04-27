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
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    
    // Style adjustments for elements of list
    private let frameWidth: CGFloat = 350
    private let frameHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 3
    private let textColor: Color = Color.primary
    private let fontSize: CGFloat = 20
    private let grayValue: CGFloat = 0.95
    
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
                            NavigationLink(

                                destination: ProfileView(
                                    link: value,
                                    diverID: String(value.utf16.dropFirst(67)) ?? "")) {
                                        GeometryReader { geometry in
                                            HStack {
                                                Text(key)
                                                    .foregroundColor(textColor)
                                                    .font(.system(size: fontSize))
                                                    .padding()
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color.gray)
                                                    .padding()
                                            }
                                            .frame(width: frameWidth,
                                                   height: frameHeight)
                                            .background(rowColor)
                                            .cornerRadius(cornerRadius)
                                        }
                                        .frame(width: frameWidth,
                                               height: frameHeight)
                                        .onDisappear {
                                            resultSelected = true
                                        }
                                        .onAppear{
                                            resultSelected = false
                                        }
                                    }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Results")
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
