//
//  ProfileView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct ProfileView: View {
    var profileLink: String
    var diverID : String
    @Binding var hideTabBar: Bool
    
    init(hideTabBar: Binding<Bool>, link: String = "", diverID: String = "00000") {
        self.profileLink = link
        self._hideTabBar = hideTabBar
        self.diverID = diverID
    }
    
    var body: some View {
        VStack {
            VStack {
//                BackgroundView()
//                    .offset(y: -40)
//                    .ignoresSafeArea(edges: .top)
//                    .frame(height: 50)

                ProfileImage(diverID: diverID)
                    //.offset(y: -20)
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
                //.offset(y: -70)
                .padding()

            }
            Text(diverID)
            MeetList(hideTabBar: $hideTabBar)
                //.offset(y: -100)
                .frame(height: 400)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(hideTabBar: .constant(false))
    }
}
