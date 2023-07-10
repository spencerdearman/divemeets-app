//
//  FinishedLiveResultsView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 7/10/23.
//

import SwiftUI
import SwiftSoup

struct FinishedLiveResultsView: View {
    @State private var html: String = ""
    @State private var elements: [[String]]?
    @State private var eventTitle: String?
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    private let parser = FinishedLiveResultsParser()
    private let getTextModel = GetTextAsyncModel()
    
    var link: String
    
    
    
    var body: some View {
        ZStack {
            LRWebView(request: link, html: $html)
            
            Custom.background.ignoresSafeArea()
            
            if let eventTitle = eventTitle,
               let elements = elements {
                VStack {
                    Text(eventTitle)
                        .font(.title)
                        .bold()
                        .padding()
                        .multilineTextAlignment(.center)
                    Divider()
                    ScalingScrollView(records: elements, rowSpacing: 50) { (elem) in
                        LivePersonBubbleView(elements: elem)
                    }
                    .padding(.bottom, maxHeightOffset)
                }
            }
        }
        .onChange(of: html) { _ in
            Task {
                await parser.getFinishedLiveResultsRecords(html: html)
                elements = parser.resultsRecords
                eventTitle = parser.eventTitle
            }
        }
    }
}

struct LivePersonBubbleView: View {
    @Environment(\.colorScheme) var currentMode
    var elements: [String]
    
    // place, first, last, link, team, score, scoreLink, eventAvgScore, avgRoundScore
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .foregroundColor(Custom.tileColor)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(alignment: .firstTextBaseline) {
                        NavigationLink(destination: ProfileView(profileLink: elements[3])) {
                            VStack(alignment: .leading) {
                                Text(elements[1])
                                Text(elements[2])
                            }
                        }
                        
                        Text(elements[4])
                            .foregroundColor(.gray)
                            .font(.title3)
                        Spacer()
                    }
                    .lineLimit(2)
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    NavigationLink(destination: AnyView(_fromValue: Text(elements[6]))) {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Custom.thinMaterialColor)
                                .mask(RoundedRectangle(cornerRadius: 60, style: .continuous))
                                .shadow(radius: 2)
                                .frame(width: 200, height: 40)
                            // Score Link is elements[6]
                            Text("Score: " + elements[5])
                                .fontWeight(.semibold)
                                .scaledToFit()
                        }
                    }
                }
                
                HStack {
                    Text("Place: " + elements[0])
                        .fontWeight(.semibold)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Event Avg Score: " + elements[7])
                            .font(.footnote.weight(.semibold))
                        Text("Avg Round Score: " + elements[8])
                            .font(.footnote.weight(.semibold))
                    }
                }
            }
            .padding(20)
        }
    }
}
