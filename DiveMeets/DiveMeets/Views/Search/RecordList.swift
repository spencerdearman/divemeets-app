//
//  RecordList.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct RecordList: View {
    @Environment(\.colorScheme) var currentMode
    
    @Binding var hideTabBar: Bool
    @Binding var records: [String: String]
    @Binding var personSelection: String?
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    
    // Style adjustments for elements of list
    private let frameWidth: CGFloat = 350
    private let frameHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 3
    private let fontSize: CGFloat = 20
    private let grayValue: CGFloat = 0.95
    private let grayValueDark: CGFloat = 0.10
    
    var body: some View {
        let rowColor: Color = currentMode == .light ? Color.white : Color.black
        let textColor: Color = currentMode == .light ? Color.black : Color.white
        NavigationView {
            ZStack {
                // Background color for View
                (
                    currentMode == .light
                    ? Color(red: grayValue, green: grayValue, blue: grayValue)
                    : Color(red: grayValueDark, green: grayValueDark, blue: grayValueDark)
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: rowSpacing) {
                        ForEach(records.sorted(by: <), id: \.key) { key, value in
                            NavigationLink(
                                destination: ProfileView(
                                    hideTabBar: $hideTabBar, link: value,
                                    diverID: String(
                                        value.utf16.dropFirst(67)) ?? "")) {
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
                                            .onAppear {
                                                personSelection = nil
                                            }
                                        }
                        }
                    }
                    
                    // Scroll tracking to hide/show tab bar when scrolling down/up
                    .overlay(
                        
                        GeometryReader {proxy -> Color in
                            
                            let minY = proxy.frame(in: .named("SCROLL")).minY
                            
                            /*
                             * Duration to hide TabBar
                             */
                            let durationOffset: CGFloat = 0
                            
                            DispatchQueue.main.async {
                                if minY < offset {
                                    if (offset < 0 &&
                                        -minY > (lastOffset + durationOffset)) {
                                        withAnimation(.easeOut.speed(1.5)) {
                                            hideTabBar = true
                                        }
                                        lastOffset = -offset
                                    }
                                }
                                if offset < minY {
                                    if (offset < 0 &&
                                        -minY < (lastOffset - durationOffset)) {
                                        withAnimation(.easeIn.speed(1.5)) {
                                            hideTabBar = false
                                        }
                                        lastOffset = -offset
                                    }
                                }
                                
                                self.offset = minY
                            }
                            
                            return Color.clear
                        }
                        
                    )
                    .padding()
                }
                .coordinateSpace(name: "SCROLL")
                .navigationTitle("Results")
            }
        }
    }
}
