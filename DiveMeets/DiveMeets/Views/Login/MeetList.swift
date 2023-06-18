//
//  MeetList.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct MeetList: View {
    @Environment(\.colorScheme) var currentMode
    var profileLink: String
    @State var diverData: [Int:[String:[String:(String, Double, String, String)]]] = [:]
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    @State var meets: [MeetEvent] = []
    @State var navStatus: Bool = true
    @StateObject private var parser = EventHTMLParser()
    
    // Style adjustments for elements of list
    private let frameWidth: CGFloat = 350
    private let frameHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 10
    private let fontSize: CGFloat = 20
    
    private var customGray: Color {
        let gray = currentMode == .light ? 0.95 : 0.1
        return Color(red: gray, green: gray, blue: gray)
    }
    
    func createMeets(data: [Int:[String:[String:(String, Double, String, String)]]]) -> [MeetEvent]? {
        var mainMeetLink: String = ""
        
        if data.count < 1 {
            return nil
        }
        
        var meets = [MeetEvent]()
        var currentMeetEvents: [MeetEvent]? = []
        
        //Starting at 1 because the first meet in the dictionary has a key of 1
        for i in 1...diverData.count{
            if let value = diverData[i] {
                for (name, meetEvent) in value{
                    for event in meetEvent {
                        let(place, score, link, meetLink) = event.value
                        mainMeetLink = meetLink
                        currentMeetEvents!.append(MeetEvent(name: event.key, place: Int(place), score: score, isChild: true, link: link))
                    }
                    let meet = MeetEvent(name: name, children: currentMeetEvents, link: mainMeetLink)
                    meets.append(meet)
                    currentMeetEvents = []
                }
            }
        }
        return meets
    }
    
    
    var body: some View {
        
        ZStack{}
            .onAppear {
                Task {
                    await parser.parse(urlString: profileLink)
                    diverData = parser.myData
                    meets = createMeets(data: diverData) ?? []
                }
            }
        
        let rowColor: Color = currentMode == .light
        ? Color.white
        : Color.black
        
        NavigationView {
            ZStack {
                // Background color for View
                customGray.ignoresSafeArea()
                List($meets, children: \.children) { $meet in
                    (!meet.isChild ?
                     AnyView(
                        parentView(meet: $meet)
                     ) : AnyView(
                        childView(meet: $meet, navStatus: $navStatus)
                     ))
                    .frame(width: frameWidth,
                           height: meet.isOpen ? 400: 45)
                }
            }
            .navigationTitle("Meets")
        }
    }
}

struct childView: View{
    @Binding var meet: MeetEvent
    @Binding var navStatus: Bool
    
    var body: some View{
        Button(action: {}, label: {
            Text(meet.name)
        })
        .simultaneousGesture(TapGesture().onEnded {
            meet.isOpen = true
        })
        .fullScreenCover(isPresented: $meet.isOpen) {
            Event(isFirstNav: $navStatus, meet: $meet)
        }
    }
}

struct parentView: View{
    @Binding var meet: MeetEvent
    
    var body: some View{
        HStack {
            Image(systemName: "link")
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
            
            HStack {
                Text(meet.name)
            }
            .foregroundColor(.primary)
            .padding()
            
            Spacer()
        }
    }
}

