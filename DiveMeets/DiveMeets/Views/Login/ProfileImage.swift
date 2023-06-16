//
//  ProfileImage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct ProfileImage: View {
    @Environment(\.colorScheme) var currentMode
    let diverID: String
    
    var body: some View {
        let imageUrlString =
        "https://secure.meetcontrol.com/divemeets/system/profilephotos/\(diverID).jpg"
        if let imageUrl = URL(string: imageUrlString) {
            AsyncImage(url: imageUrl) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width:200, height:300)
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(.white, lineWidth: 4)
                        }
                        .shadow(radius: 7)
                } else if phase.error != nil {
                    Image("defaultImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width:200, height:300)
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(.white, lineWidth: 4)
                        }
                        .shadow(radius: 7)
                    
                } else {
                    ProgressView()
                }
            }
        }
    }
}

struct ProfileImage_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            ProfileImage(diverID: "16241").preferredColorScheme($0)
        }
    }
}
