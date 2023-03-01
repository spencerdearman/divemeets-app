//
//  ContentView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            VStack {
                BackgroundView()
                    .offset(y: -40)
                    .ignoresSafeArea(edges: .top)
                    .frame(height: 50)

                ProfileImage()
                    .offset(y: -20)

                VStack(alignment: .leading) {
                    Text("Spencer Dearman")
                        .font(.title)

                    HStack {
                        Text("University of Chicago")
                        Spacer()
                        Text("Oakton, VA")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    Divider()
                }
                .offset(y: -70)
                .padding()

            }
            
            MeetList()
                .offset(y: -100)
                .frame(height: 400)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
