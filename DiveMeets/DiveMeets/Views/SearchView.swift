//
//  SearchView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/2/23.
//

import SwiftUI

enum SearchType: String, CaseIterable {
    case person = "Diver, Coach, or Judge"
    case meet = "Meet"
}

/// Checks that for a given SearchType, at least one of the relevant fields has a value, and returns true if so.
/// If all relevant fields are empty, returns false
private func checkFields(selection: SearchType, firstName: String = "",
                         lastName: String = "", meetName: String = "",
                         orgName: String = "", meetYear: String = "") -> Bool {
    switch selection {
    case .person:
        return firstName != "" || lastName != ""
    case .meet:
        return meetName != "" || orgName != "" || meetYear != ""
    }
}

struct SearchView: View {
    @State private var selection: SearchType = .person
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var meetName: String = ""
    @State private var orgName: String = ""
    @State private var meetYear: String = ""
    @State private var searchSubmitted: Bool = false
    @State var parsedLinks: [String: String] = [:]
    @State var dmSearchSubmitted: Bool = false
    @State var linksParsed: Bool = false
    @Binding var hideTabBar: Bool
    
    @ViewBuilder
    var body: some View {
        ZStack{
            if searchSubmitted {
                SwiftUIWebView(firstName: $firstName, lastName: $lastName, parsedLinks: $parsedLinks, searchSubmitted: $dmSearchSubmitted, linksParsed: $linksParsed)
            }
            
            Color.white.ignoresSafeArea()
            
            /// Submit button doesn't switch pages in preview, but it works in Simulator
            SearchInputView(selection: $selection, firstName: $firstName, lastName: $lastName, meetName: $meetName,
                            orgName: $orgName, meetYear: $meetYear,
                            searchSubmitted: $searchSubmitted, parsedLinks: $parsedLinks, dmSearchSubmitted: $dmSearchSubmitted, linksParsed: $linksParsed, hideTabBar: $hideTabBar)
        }
        .onDisappear {
            searchSubmitted = false
        }
        
    }
}
//
///// Currently just for testing that the results are being captured before scraping
//struct SearchResultsView: View {
//    @Binding var selection: SearchType
//    @Binding var firstName: String
//    @Binding var lastName: String
//    @Binding var meetName: String
//    @Binding var orgName: String
//    @Binding var meetYear: String
//    @Binding var searchSubmitted: Bool
//
//    var body: some View {
//        VStack {
//            /// Temporary for testing purposes before we scrape
//            Text("Sending...")
//            if selection == .meet {
//                Text(meetName)
//                Text(orgName)
//                Text(meetYear)
//            } else {
//                Text(firstName)
//                Text(lastName)
//            }
//            Button(action: {
//                searchSubmitted = false
//            }, label: {
//                Text("Back")
//            })
//            .buttonStyle(.bordered)
//            .padding()
//        }
//    }
//}

struct SearchInputView: View {
    @State private var showError: Bool = false
    @Binding var selection: SearchType
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var meetName: String
    @Binding var orgName: String
    @Binding var meetYear: String
    @Binding var searchSubmitted: Bool
    @Binding var parsedLinks: [String: String]
    @Binding var dmSearchSubmitted: Bool
    @Binding var linksParsed: Bool
    @Binding var hideTabBar: Bool
    private let cornerRadius: CGFloat = 20
    private let selectedBGColor: Color = Color.blue
    /// Light gray
    private let deselectedBGColor: Color = Color(red: 0.94, green: 0.94,
                                                 blue: 0.94)
    private let selectedTextColor: Color = Color.white
    private let deselectedTextColor: Color = Color.blue
    
    var body: some View {
        VStack {
            VStack {
                Text("Search")
                    .font(.title)
                    .bold()
                    .padding(.bottom, 155)
                HStack {
                    Text("Type:")
                    HStack {
                        Button(action: {
                            if selection != .person {
                                showError = false
                                searchSubmitted = false
                                linksParsed = false
                                parsedLinks = [:]
                                meetName = ""
                                orgName = ""
                                meetYear = ""
                                selection = .person
                            }
                        }, label: {
                            Text(SearchType.person.rawValue)
                                .animation(nil, value: selection)
                        })
                        .buttonStyle(.bordered)
                        .foregroundColor(selection == .person
                                         ? selectedTextColor
                                         : deselectedTextColor)
                        .background(selection == .person
                                    ? selectedBGColor
                                    : deselectedBGColor)
                        .cornerRadius(cornerRadius)
                        Button(action: {
                            if selection != .meet {
                                showError = false
                                searchSubmitted = false
                                linksParsed = false
                                parsedLinks = [:]
                                firstName = ""
                                lastName = ""
                                selection = .meet
                            }
                        }, label: {
                            Text(SearchType.meet.rawValue)
                                .animation(nil, value: selection)
                        })
                        .buttonStyle(.bordered)
                        .foregroundColor(selection == .meet
                                         ? selectedTextColor
                                         : deselectedTextColor)
                        .background(selection == .meet
                                    ? selectedBGColor
                                    : deselectedBGColor)
                        .cornerRadius(cornerRadius)
                    }
                }
                .padding([.leading, .trailing])
            }
            
            if selection == .meet {
                MeetSearchView(meetName: $meetName, orgName: $orgName,
                               meetYear: $meetYear)
            } else {
                DiverSearchView(firstName: $firstName, lastName: $lastName)
            }
            
            VStack {
                Button(action: {
                    /// Need to initially set search to false so webView gets recreated
                    searchSubmitted = false
                    /// Only submits a search if one of the relevant fields is filled, otherwise toggles error
                    if checkFields(selection: selection, firstName: firstName,
                                   lastName: lastName, meetName: meetName,
                                   orgName: orgName, meetYear: meetYear) {
                        showError = false
                        searchSubmitted = true
                        dmSearchSubmitted = false
                        linksParsed = false
                        parsedLinks = [:]
                    } else {
                        showError = true
                        searchSubmitted = false
                        dmSearchSubmitted = false
                        linksParsed = false
                        parsedLinks = [:]
                    }
                }, label: {
                    Text("Submit")
                        .animation(nil, value: selection)
                })
                .buttonStyle(.bordered)
                .cornerRadius(cornerRadius)
            .animation(nil, value: selection)
                if searchSubmitted && !linksParsed {
                    ProgressView()
                }
            }
            if showError {
                Text("You must enter at least one field to search")
                    .foregroundColor(Color.red)
                
            } else {
                Text("")
            }
            
            if linksParsed {
                RecordList(hideTabBar: $hideTabBar, records: $parsedLinks)
            }
            
            Spacer()
        }
        .onAppear {
            showError = false
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
                            .tag(String($0))
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 150, height: 85)
                .padding(.trailing)
            }
            .offset(y: -10)
        }
        .padding([.top, .leading, .trailing])
        .onAppear {
            meetName = ""
            orgName = ""
            meetYear = ""
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(hideTabBar: .constant(false))
    }
}
