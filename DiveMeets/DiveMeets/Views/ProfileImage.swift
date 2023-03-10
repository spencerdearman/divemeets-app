//
//  ProfileImage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct ProfileImage: View {
    @Environment(\.colorScheme) var currentMode
    
    var body: some View {
        Image("spencerdearman")
            .resizable()
            .scaledToFit()
            .frame(width:200, height:300)
            .clipShape(Circle())
            .overlay {
                Circle().stroke(currentMode == .light ? .white : .black,
                                lineWidth: 4)
            }
            .shadow(radius: 7)
        
    }
}

struct ProfileImage_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            ProfileImage().preferredColorScheme($0)
        }
    }
}
