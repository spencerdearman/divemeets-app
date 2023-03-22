//
//  ProfileView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct ProfileView: View {
    var profileLink: String
    @Binding var hideTabBar: Bool
    
    init(hideTabBar: Binding<Bool>, link: String = "") {
        self.profileLink = link
        self._hideTabBar = hideTabBar
    }
    
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
            
            MeetList(hideTabBar: $hideTabBar)
                .offset(y: -100)
                .frame(height: 400)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(hideTabBar: .constant(false))
    }
}
