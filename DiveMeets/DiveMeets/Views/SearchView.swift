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
    @State private var meetYear: Int = 2023
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
    @Binding var meetYear: Int
    @Binding var searchSubmitted: Bool
    
    var body: some View {
        VStack {
            Text("Sending...")
            let items = [firstName, lastName, meetName, orgName, String(meetYear)]
            ForEach(items, id: \.self) { i in
                Text(i)
            }
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
    @Binding var meetYear: Int
    @Binding var searchSubmitted: Bool
    
    let options = ["Diver, Coach, or Judge", "Meet"]
    
    var body: some View {
        VStack {
            Text("Search")
                .font(.title)
                .bold()
            Spacer()
            VStack {
                Picker("Search Type:", selection: $selection) {
                    ForEach(options, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 275, height: 100)
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
            Spacer()
            Spacer()
        }
    }
}

struct MeetSearchView: View {
    @Binding var meetName: String
    @Binding var orgName: String
    @Binding var meetYear: Int
    
    var body: some View {
        VStack{
            HStack {
                Text("Meet Name:")
                    .padding(.leading)
                TextField("", text: $meetName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing)
            }
            HStack {
                Text("Organization Name:")
                    .padding(.leading)
                TextField("", text: $orgName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing)
            }
            HStack {
                Text("Meet Year:")
                    .padding(.leading)
                Picker("MM", selection: $meetYear) {
                    ForEach(2004...2023, id: \.self) {
                        Text(String($0))
                    }
                }
                .padding(.trailing)
            }
        }
        .padding()
        .onAppear {
            meetName = ""
            orgName = ""
            meetYear = 2023
        }
    }
}

struct DiverSearchView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    
    var body: some View {
        HStack {
            TextField("First Name", text: $firstName)
                .textFieldStyle(.roundedBorder)
                .padding(.leading)
            TextField("Last Name", text: $lastName)
                .textFieldStyle(.roundedBorder)
                .padding(.trailing)
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
