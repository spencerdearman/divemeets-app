//
//  MeetPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//
import Foundation
import SwiftUI

struct Event: Hashable, Codable {
    var meetEvent: String
    var meetPlace: Int
    var meetScore: Double
}

struct EventView: View {
    var eventInstance: Event
    
    var body: some View {
        Text(eventInstance.meetEvent)
    }
}

struct MeetPage: View {
    var meetInstance: Meet
    @Binding var hidingTabBar: Bool
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    
    /// Style adjustments for elements of list
    private let frameWidth: CGFloat = 350
    private let frameHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 50
    private let rowSpacing: CGFloat = 3
    private let rowColor: Color = Color.white
    private let textColor: Color = Color.black
    private let fontSize: CGFloat = 20
    private let grayValue: CGFloat = 0.95
    
    var body: some View {
        let events: [Event] = meetInstance.meetEvents
        ZStack {
            /// Background color for View
            Color(red: grayValue, green: grayValue, blue: grayValue)
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: rowSpacing) {
                    ForEach(events, id: \.self)  { event in
                        NavigationLink(
                            destination: EventPage(ev1: event)) {
                                GeometryReader { geometry in
                                    HStack {
                                        EventView(eventInstance: event)
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
                            }
                    }
                }
                /// Scroll tracking to hide/show tab bar when scrolling down/up
                .overlay(
                    
                    GeometryReader {proxy -> Color in
                        
                        let minY = proxy.frame(in: .named("SCROLL")).minY
                        
                        /*
                         * Duration to hide TabBar
                         */
                        let durationOffset: CGFloat = 0
                        
                        DispatchQueue.main.async {
                            if minY < offset {
                                print("down")
                                
                                if (offset < 0 &&
                                    -minY > (lastOffset + durationOffset)) {
                                    withAnimation(.easeOut.speed(1.5)) {
                                        hidingTabBar = true
                                    }
                                    lastOffset = -offset
                                }
                            }
                            if offset < minY {
                                print("up")
                                
                                if (offset < 0 &&
                                    -minY < (lastOffset - durationOffset)) {
                                    withAnimation(.easeIn.speed(1.5)) {
                                        hidingTabBar = false
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
            .navigationTitle("Events")
        }
    }
}
/*
 struct MeetPage_Previews: PreviewProvider {
 static var previews: some View {
 MeetPage(meetInstance: meets[0], hidingTabBar: $hideTabBar)
 }
 }*/
