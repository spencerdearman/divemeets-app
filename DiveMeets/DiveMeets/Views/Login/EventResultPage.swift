//
//  EventResultPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/26/23.
//

import SwiftUI

struct EventResultPage: View {
    @StateObject private var parser = EventPageHTMLParser()
    @State var eventTitle: String = ""
    @State var meetLink: String = "https://secure.meetcontrol.com/divemeets/system/eventresultsext.php?meetnum=7984&eventnum=1020&eventtype=9"
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
                    eventTitle = resultData[0][8]
                }
            }
        
        VStack{
            Text(eventTitle)
                .font(.title)
                .bold()
            Divider()
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
    //  (Place  Name   NameLink  Team  TeamLink Score ScoreLink Score Diff. MeetName)
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
                    HStack(alignment: .lastTextBaseline) {
                        Text(elements[1])
                            .font(.title3)
                            .bold()
                            .scaledToFit()
                            .minimumScaleFactor(0.5)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                        Text(elements[3])
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    Spacer()
                    HStack{
                        Text("Place: " + elements[0])
                        Spacer()
                        Text("Score: " + elements[5])
                        Spacer()
                        Text("Difference: " + elements[7])
                    }
                    .font(.subheadline)
                    .scaledToFit()
                    .minimumScaleFactor(0.5)
                }
            }
            .padding()
        }
        .onTapGesture {
            print(elements[3])
        }
    }
}
