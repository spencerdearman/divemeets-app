//
//  SearchView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/2/23.
//

import SwiftUI

struct SearchView: View {
    @State private var selection: String = "Diver, Coach, or Judge"
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var meetName: String = ""
    @State private var orgName: String = ""
    @State private var meetYear: String = ""
    @State private var searchSubmitted: Bool = false
    
    @ViewBuilder
    var body: some View {
        /// Submit button doesn't switch pages in preview, but it works in Simulator
        if searchSubmitted {
            SearchResultsView(selection: $selection, firstName: $firstName, lastName: $lastName, meetName: $meetName, orgName: $orgName, meetYear: $meetYear, searchSubmitted: $searchSubmitted)
                .onDisappear {
                    searchSubmitted = false
                }
        } else {
            SearchInputView(selection: $selection, firstName: $firstName, lastName: $lastName, meetName: $meetName, orgName: $orgName, meetYear: $meetYear, searchSubmitted: $searchSubmitted)
        }
    }
}

struct SearchResultsView: View {
    @Binding var selection: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var meetName: String
    @Binding var orgName: String
    @Binding var meetYear: String
    @Binding var searchSubmitted: Bool
    
    var body: some View {
        VStack {
            /// Temporary for testing purposes before we scrape
            Text("Sending...")
//            let items = [firstName, lastName, meetName, orgName, String(meetYear)]
            if selection == "Meet" {
                Text(meetName)
                Text(orgName)
                Text(String(meetYear))
            } else {
                Text(firstName)
                Text(lastName)
            }
//            ForEach(items, id: \.self) { i in
//                if selection == "Meet" && type(of: i) == Int {
//                    Text(i)
//                } else {
//                    Text(i)
//                }
//
//            }
            Button(action: {
                searchSubmitted = false
            }, label: {
                Text("Back")
            })
            .buttonStyle(.bordered)
            .padding()
        }
    }
}

struct SearchInputView: View {
    @Binding var selection: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var meetName: String
    @Binding var orgName: String
    @Binding var meetYear: String
    @Binding var searchSubmitted: Bool
    private let cornerRadius: CGFloat = 10
    private let selectedBGColor: Color = Color.blue
    private let deselectedBGColor: Color = Color(red: 0.94, green: 0.94, blue: 0.94)
    private let selectedTextColor: Color = Color.white
    private let deselectedTextColor: Color = Color.blue
    
//    let options = ["Diver, Coach, or Judge", "Meet"]
    
    var body: some View {
        VStack {
            Text("Search")
                .font(.title)
                .bold()
            Spacer()
            VStack {
                HStack {
                    Text("Search Type:")
                    HStack {
                        Button(action: {
                            selection = "Diver, Coach, or Judge"
                        }, label: {
                            Text("Diver, Coach, or Judge")
                                .animation(nil, value: selection)
                        })
                        .buttonStyle(.bordered)
                        .foregroundColor(selection != "Meet" ? selectedTextColor : deselectedTextColor)
                        .background(selection != "Meet" ? selectedBGColor : deselectedBGColor)
                        .cornerRadius(cornerRadius)
                        Button(action: {
                            selection = "Meet"
                        }, label: {
                            Text("Meet")
                                .animation(nil, value: selection)
                        })
                        .buttonStyle(.bordered)
                        .foregroundColor(selection == "Meet" ? selectedTextColor : deselectedTextColor)
                        .background(selection == "Meet" ? selectedBGColor : deselectedBGColor)
                        .cornerRadius(cornerRadius)
                    }
                }
//                Picker("Search Type:", selection: $selection) {
//                    ForEach(options, id: \.self) {
//                        Text($0)
//                    }
//                }
//                .pickerStyle(.wheel)
//                .frame(width: 275, height: 100)
            }
            
            if selection == "Meet" {
                MeetSearchView(meetName: $meetName, orgName: $orgName, meetYear: $meetYear)
            } else {
                DiverSearchView(firstName: $firstName, lastName: $lastName)
            }
            
            Button(action: {
                searchSubmitted.toggle()
            }, label: {
                Text("Submit")
            })
            .buttonStyle(.bordered)
            .cornerRadius(cornerRadius)
            Spacer()
            Spacer()
        }
    }
}

struct MeetSearchView: View {
    @Binding var meetName: String
    @Binding var orgName: String
    @Binding var meetYear: String
    
    var body: some View {
        VStack{
            HStack {
                Text("Meet Name:")
                    .padding(.leading)
                TextField("Meet Name", text: $meetName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing)
            }
            HStack {
                Text("Organization Name:")
                    .padding(.leading)
                TextField("Organization Name", text: $orgName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing)
            }
            HStack {
                Text("Meet Year:")
                    .padding(.leading)
                Picker("", selection: $meetYear) {
                    Text("")
                    ForEach((2004...2023).reversed(), id: \.self) {
                        Text(String($0))
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 150, height: 100)
                .padding(.trailing)
            }
        }
        .padding()
        .onAppear {
            meetName = ""
            orgName = ""
            meetYear = ""
        }
    }
}

struct DiverSearchView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    
    var body: some View {
        VStack {
            HStack {
                Text("First Name:")
                    .padding(.leading)
                TextField("First Name", text: $firstName)
                    .textFieldStyle(.roundedBorder)
                .padding(.trailing)
            }
            HStack {
                Text("Last Name:")
                    .padding(.leading)
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(.roundedBorder)
                .padding(.trailing)
            }
        }
        .padding()
        .onAppear {
            firstName = ""
            lastName = ""
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
