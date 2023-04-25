//
//  MeetPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct MeetPage: View {
    
    var meetInstance: Meet
    
    var body: some View {
        VStack {
            Divider()
            Text(meetInstance.meetName)
                .font(.title2)
            Divider()
            
            if meetInstance.meetEvents.count == 1{
                Text(meetInstance.meetEvents[0])
                    .font(.title3)
                HStack {
                    Text("Place: " + String(meetInstance.meetPlaces[0]))
                    
                    Text("Score " +
                         String(meetInstance.meetScores[0]))
                }
                .font(.subheadline)
            }
            else{
                Text(meetInstance.meetEvents[0])
                    .font(.title3)
                HStack {
                    Text("Place: " + String(meetInstance.meetPlaces[0]))
                    
                    Text("Score " +
                         String(meetInstance.meetScores[0]))
                }
                Divider()
                Text(meetInstance.meetEvents[1])
                    .font(.title3)
                HStack {
                    Text("Place: " + String(meetInstance.meetPlaces[1]))
                    
                    Text("Score " +
                         String(meetInstance.meetScores[1]))
                }
            }

        }
    }
}

struct MeetPage_Previews: PreviewProvider {
    static var previews: some View {
        MeetPage(meetInstance: meets[0])
    }
}
