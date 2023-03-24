//
//  ProfileImage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct ProfileImage: View {
    let diverID: String
    
    var body: some View {
        let imageUrlString = "https://secure.meetcontrol.com/divemeets/system/profilephotos/\(diverID).jpg"
        let imageUrl = URL(string: imageUrlString)!
        
        AsyncImage(url: imageUrl) { image in
            image
                .resizable()
                .scaledToFit()
                .frame(width:200, height:300)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(.white, lineWidth: 4)
                }
                .shadow(radius: 7)
        } placeholder: {
            ProgressView()
        }
    }
}

struct ProfileImage_Previews: PreviewProvider {
    static var previews: some View {
        ProfileImage(diverID: "51197")
    }
}
