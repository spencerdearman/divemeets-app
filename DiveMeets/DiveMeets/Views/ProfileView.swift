//
//  ProfileView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

extension String {
    func slice(from: String, to: String) -> String? {
        guard let rangeFrom = range(of: from)?.upperBound else { return nil }
        guard let rangeTo = self[rangeFrom...].range(of: to)?.lowerBound else { return nil }
        return String(self[rangeFrom..<rangeTo])
    }
}



struct ProfileView: View {
    var profileLink: String
    var diverID : String
    @State var diverData : [Array<String>] = []
    @Binding var hideTabBar: Bool
    @StateObject private var parser = HTMLParser()
    
    init(hideTabBar: Binding<Bool>, link: String, diverID: String = "00000") {
        self.profileLink = link
        self._hideTabBar = hideTabBar
        self.diverID = diverID
    }
    
    var body: some View {
        
        ZStack{}
            .onAppear{
                diverData = parser.parse(urlString: profileLink)
            }
        VStack {
            VStack {
                Spacer()
                ProfileImage(diverID: diverID)
                    .offset(y:25)
                VStack(alignment: .leading) {
                    HStack (alignment: .firstTextBaseline){
                        diverData != [] ? Text(diverData[0][0].slice(from: "Name: ", to: " City/State") ?? "") .font(.title) : Text("")
                        Text(diverID)
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    Divider()
                    HStack (alignment: .firstTextBaseline){
                        Image(systemName: "house.fill")
                        diverData != [] ? Text((diverData[0][0].slice(from: " City/State: ", to: " Country")  ?? "") + ", " + (diverData[0][0].slice(from: " Country: ", to: " Gender") ?? "")): Text("")
                    }
                    .font(.subheadline)
                    HStack (alignment: .firstTextBaseline) {
                        Image(systemName: "person.circle")
                        diverData != [] ? Text("Gender: " + (diverData[0][0].slice(from: " Gender: ", to: " Age") ?? "")) : Text("")
                        diverData != [] ? Text("Age: " + (diverData[0][0].slice(from: " Age: ", to: " FINA") ?? "")) : Text("")
                        diverData != [] ? Text("FINA Age: " + (diverData[0][0].slice(from: " FINA Age: ", to: " High") ?? "")) : Text("")
                    }
                    .font(.subheadline)
                    .padding([.leading], 2)
                    
                    Divider()
                }
                .padding()
                
            }
            MeetList(profileLink: profileLink, hideTabBar: $hideTabBar)
                .frame(height: 230)
                .offset(y: -250)
                .background(Color.white)
            
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            ProfileView(hideTabBar: .constant(false), link: "").preferredColorScheme($0)
        }
    }
}
