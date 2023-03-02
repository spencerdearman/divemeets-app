//
//  SearchView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/2/23.
//

import SwiftUI

struct SearchView: View {
    @State private var selection: String = "Meet"
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var meetName: String = ""
    @State private var orgName: String = ""
    @State private var meetYear: Int = 0
    @State private var searchSubmitted: Bool = false
    
    let options = ["Diver, Coach, or Judge", "Meet"]
    
    @ViewBuilder
    var body: some View {
        if searchSubmitted {
            SearchResultsView()
        } else {
            SearchInputView(firstName: $firstName, lastName: $lastName, meetName: $meetName, orgName: $orgName, meetYear: $meetYear, searchSubmitted: $searchSubmitted)
        }
    }
}

struct SearchResultsView: View {
    var body: some View {
        Text("Hello")
    }
}

struct SearchInputView: View {
    @State private var selection: String = "Meet"
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
                //                Text("Search Type")
                //                    .font(.headline)
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
                searchSubmitted = true
            }, label: {
                Text("Submit")
            })
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
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
