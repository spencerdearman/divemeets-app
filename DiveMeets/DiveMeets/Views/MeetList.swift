//
//  MeetList.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct MeetList: View {
    @Environment(\.colorScheme) var currentMode
    
    @Binding var hideTabBar: Bool
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    
    /// Style adjustments for elements of list
    private let frameWidth: CGFloat = 350
    private let frameHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 3
    private let fontSize: CGFloat = 20
    
    var body: some View {
        let rowColor: Color = currentMode == .light
        ? Color.white
        : Color.black
        
        NavigationView {
            ZStack {
                /// Background color for View
                Color.clear.background(.thinMaterial)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: rowSpacing) {
                        ForEach(meets) { meet in
                            NavigationLink(
                                destination: MeetPage(meetInstance: meet)) {
                                    GeometryReader { geometry in
                                        HStack {
                                            MeetElement(meet0: meet)
                                                .foregroundColor(.primary)
                                                .font(.system(size: fontSize))
                                                .padding()
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.secondary)
                                                .padding()
                                        }
                                        .frame(width: frameWidth,
                                               height: frameHeight)
                                        .background(rowColor)
                                        .cornerRadius(cornerRadius)
                                    }
                                    .frame(width: frameWidth,
                                           height: frameHeight)
                                }
                        }
                    }
                    /// Scroll tracking to hide/show tab bar when scrolling down/up
                    .overlay(
                        
                        GeometryReader {proxy -> Color in
                            
                            let minY = proxy.frame(in: .named("SCROLL")).minY
                            
                            /// Duration to hide TabBar
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
                .navigationTitle("Meets")
            }
        }
    }
}

struct MeetList_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            MeetList(hideTabBar: .constant(false)).preferredColorScheme($0)
        }
    }
}

