//
//  ProfileView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct ProfileView: View {
    var profileLink: String
    @State var diverData : [[String]] = []
    @State var profileType : String = ""
    @StateObject private var parser = HTMLParser()
    
    var diverID: String {
        String(profileLink.suffix(5))
    }
    
    var body: some View {
        
        ZStack{}
            .onAppear {
                Task {
                    await parser.parse(urlString: profileLink)
                    diverData = parser.myData
                    let divers = diverData[0][0].slice(from: "Divers:", to: "Judging") ?? ""
                    
                    if divers != "" {
                        profileType = "Coach"
                    } else {
                        profileType = "Diver"
                    }
                }
            }
        
        if profileType == "Diver" {
            VStack {
                VStack {
                    ProfileImage(diverID: diverID)
                        .offset(y:-100)
                    VStack {
                        VStack(alignment: .leading) {
                            HStack (alignment: .firstTextBaseline) {
                                let firstName = diverData[0][0].slice(from: "Name: ", to: " ") ?? ""
                                let lastName =
                                diverData[0][0].slice(from: firstName + " ", to: " ") ?? ""
                                
                                diverData != []
                                ? Text(firstName + " " + lastName) .font(.title)
                                : Text("")
                                
                                Text(diverID)
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                            Divider()
                            HStack (alignment: .firstTextBaseline) {
                                Image(systemName: "house.fill")
                                diverData != []
                                ? Text(
                                    (diverData[0][0].slice(from: "State: ", to: " Country")  ?? "")
                                    + ", "
                                    + (diverData[0][0].slice(from: " Country: ",
                                                             to: " Gender") ?? ""))
                                : Text("")
                            }
                            .font(.subheadline)
                            HStack (alignment: .firstTextBaseline) {
                                Image(systemName: "person.circle")
                                diverData != []
                                ? Text("Gender: " +
                                       (diverData[0][0].slice(from: " Gender: ", to: " Age") ?? ""))
                                : Text("")
                                diverData != []
                                ? Text("Age: " +
                                       (diverData[0][0].slice(from: " Age: ", to: " FINA") ?? ""))
                                : Text("")
                                diverData != []
                                ? Text("FINA Age: " +
                                       (diverData[0][0].slice(from: " FINA Age: ",
                                                              to: " High") ?? ""))
                                : Text("")
                            }
                            .font(.subheadline)
                            .padding([.leading], 2)
                            Divider()
                        }
                        .offset(y:-150)
                    }
                    .padding()
                    
                }
                MeetList(profileLink: profileLink)
                    .offset(y: -160)
            }
        } else {
            VStack {
                VStack {
                    ProfileImage(diverID: diverID)
                        .offset(y:-100)
                    VStack{
                        VStack(alignment: .leading) {
                            HStack (alignment: .firstTextBaseline){
                                diverData != []
                                ? Text(diverData[0][0].slice(from: "Name: ",
                                                             to: " City/State") ?? "").font(.title)
                                : Text("")
                                
                                Text(diverID)
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                            Divider()
                            HStack (alignment: .firstTextBaseline){
                                Image(systemName: "house.fill")
                                diverData != []
                                ? Text(
                                    (diverData[0][0].slice(from: " City/State: ",
                                                           to: " Country")  ?? "")
                                    + ", "
                                    + (diverData[0][0].slice(from: " Country: ",
                                                             to: " Gender") ?? "")): Text("")
                            }
                            .font(.subheadline)
                            HStack (alignment: .firstTextBaseline) {
                                Image(systemName: "person.circle")
                                diverData != []
                                ? Text("Gender: " + (diverData[0][0].slice(from: " Gender: ",
                                                                           to: " DiveMeets") ?? ""))
                                : Text("")
                            }
                            .font(.subheadline)
                            .padding([.leading], 2)
                            Divider()
                        }
                        .offset(y:-150)
                    }
                    .padding()
                }
            }
        }
    }
}
