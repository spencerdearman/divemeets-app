//
//  ProfileView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct ProfileView: View {
    @Binding var hideTabBar: Bool
    
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
        ForEach(ColorScheme.allCases, id: \.self) {
            ProfileView(hideTabBar: .constant(false)).preferredColorScheme($0)
        }
    }
}
