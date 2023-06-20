//
//  LoginProfile.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 4/27/23.
//

import SwiftUI



extension String {
    func slice(from: String, to: String) -> String? {
        guard let rangeFrom = range(of: from)?.upperBound else { return nil }
        guard let rangeTo = self[rangeFrom...].range(of: to)?.lowerBound else { return nil }
        return String(self[rangeFrom..<rangeTo])
    }
}

func fixPlacement(data: [[String]] ) -> [[String]] {
    var updated = data
    updated[0] = updated[0][0].components(separatedBy: "History")
    updated[0].remove(at: 1)
    return data
}



struct LoginProfile: View {
    var profileLink: String
    var diverID : String
    @Binding var loggedIn: Bool
    @Binding var divemeetsID: String
    @Binding var password: String
    @Binding var searchSubmitted: Bool
    @Binding var loginSuccessful: Bool
    @Binding var loginSearchSubmitted: Bool
    @State var diverData : [[String]] = []
    @State var profileType : String = ""
    @StateObject private var parser = HTMLParser()
    
    let namespace: Namespace.ID
    
    init(link: String, diverID: String = "00000", loggedIn: Binding<Bool>, divemeetsID: Binding<String>, password: Binding<String>, searchSubmitted: Binding<Bool>, loginSuccessful: Binding<Bool>, loginSearchSubmitted: Binding<Bool>, namespace: Namespace.ID) {
        self.profileLink = link
        self.diverID = diverID
        self._loggedIn = loggedIn
        self._divemeetsID = divemeetsID
        self._password = password
        self._searchSubmitted = searchSubmitted
        self._loginSuccessful = loginSuccessful
        self._loginSearchSubmitted = loginSearchSubmitted
        self.namespace = namespace
    }
    
    var body: some View {
        
        ZStack{}
            .onAppear {
                Task {
                    await parser.parse(urlString: profileLink)
                    diverData = parser.myData
                    let divers = diverData[0][0].slice(from: "Divers:", to: "Judging") ?? ""
                    print(divers)
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
                        GeometryReader { geometry in
                            ZStack{
                                Circle()
                                    .fill(Custom.darkBlue) // Circle color
                                    .frame(width: geometry.size.width
                                           * 2.5, height: geometry.size.width * 2.5).animation(.easeInOut(duration: 1.0))// Adjust the size of the circle as desired
                                    .position(x: geometry.size.width * 1, y: -geometry.size.width * 0.55) // Center the circle
                                    .shadow(radius: 15)
                                    .matchedGeometryEffect(id: "sphere1", in: namespace)
                                Circle()
                                    .fill(Custom.coolBlue) // Circle color
                                    .frame(width: geometry.size.width
                                           * 1.4, height: geometry.size.width * 1.4)
                                    .position(x: geometry.size.width * 0.8, y: geometry.size.width * 0.6)
                                    .shadow(radius: 15)
                                    .matchedGeometryEffect(id: "sphere2", in: namespace)
                                Circle()
                                    .fill(Custom.medBlue) // Circle color
                                    .frame(width: geometry.size.width
                                           * 1.2, height: geometry.size.width * 1.2)
                                    .position(x: 0, y: geometry.size.width * 0.35)
                                    .shadow(radius: 15)
                                    .matchedGeometryEffect(id: "sphere3", in: namespace)
                            }
                        }
                        ZStack{
                            Button("Logout", action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)){
                                    loggedIn = false // add this
                                    divemeetsID = ""
                                    password = ""
                                    searchSubmitted = false
                                    loginSuccessful = false
                                    loginSearchSubmitted = false
                                    diverData = []
                                    profileType = ""
                                }
                            })
                            .buttonStyle(.bordered)
                            .cornerRadius(30)
                            .offset(x:-150, y:-215)
                            ProfileImage(diverID: diverID)
                                .offset(y:-100)
                        }
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
