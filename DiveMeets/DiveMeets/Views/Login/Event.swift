//
//  Event.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/5/23.
//

import SwiftUI

struct Event: View {
    @Binding var meet: MeetEvent
    @State var diverData : [String:[String:(String, Double, String)]] = [:]
    @StateObject private var parser = EventHTMLParser()
    
    var body: some View {
        ZStack{}
        ZStack{}
            .onAppear {
                Task {
                    await parser.parse(urlString: "https://secure.meetcontrol.com/divemeets/system/profile.php?number=60480")
                    diverData = parser.myData
                    print(diverData)
                }
            }
        VStack{
            Spacer()
            Text(meet.name)
                .font(.headline)
            Spacer()
            
        }
        .onAppear(perform:{
            print("hello")
        })
        .padding()
    }
}

