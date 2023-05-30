//
//  EventResultPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/26/23.
//

import SwiftUI


struct EventResultPage: View {
    @StateObject private var parser = EventPageHTMLParser()
    @State var meetLink: String = "https://secure.meetcontrol.com/divemeets/system/eventresultsext.php?meetnum=7984&eventnum=1020&eventtype=9"
    //                     Place  Name   NameLink  Team  TeamLink Score ScoreLink Score Diff.
    //var resultData: [(Int, String, String, String, String, Double, String, String)] = []
    @State var resultData: [[String]] = []
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var body: some View {
        ZStack{}
            .onAppear {
                Task {
                    await parser.parse(urlString: meetLink)
                    resultData = parser.eventPageData
                }
            }
        
        VStack{
            Text("Event Page")
            ScalingScrollView(records: resultData) { (elem) in
                PersonBubbleView(elements: elem)
            }
            .padding(.bottom, maxHeightOffset)
        }
    }
}


struct PersonBubbleView: View {
    @Environment(\.colorScheme) var currentMode
    
    private var bubbleColor: Color {
        currentMode == .light ? .white : .black
    }
    
    //  (Place  Name   NameLink  Team  TeamLink Score ScoreLink Score Diff.)
    private var elements: [String]
    
    init(elements: [String]) {
        self.elements = elements
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(bubbleColor)
            VStack {
                VStack {
                    Text(elements[1])
                        .font(.title3)
                        .bold()
                        .scaledToFit()
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(1)
                    Spacer()
                    HStack{
                        Text("Place: " + elements[0])
                        Spacer()
                        Text("Score: " + elements[5])
                    }
                }
                Spacer()
                HStack {
                    Text("Team: " + elements[3])
                    Spacer()
                    Text("Score Differential: " + elements[7])
                }
                .font(.subheadline)
                .scaledToFit()
                .minimumScaleFactor(0.5)
            }
            .padding()
        }
        .onTapGesture {
            print(elements[3])
        }
    }
}
