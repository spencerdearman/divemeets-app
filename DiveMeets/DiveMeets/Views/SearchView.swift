//
//  SearchView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/2/23.
//

import SwiftUI

enum SearchType: String, CaseIterable {
    case diver = "Person"
    case meet = "Meet"
}

/// Checks that for a given SearchType, at least one of the relevant fields has a value, and returns true if so.
/// If all relevant fields are empty, returns false
private func checkFields(selection: SearchType, firstName: String = "",
                         lastName: String = "", meetName: String = "",
                         orgName: String = "", meetYear: String = "") -> Bool {
    switch selection {
        case .diver:
            return firstName != "" || lastName != ""
        case .meet:
            return meetName != "" || orgName != "" || meetYear != ""
    }
}

struct SearchView: View {
    @State private var selection: SearchType = .diver
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
            SearchResultsView(selection: $selection, firstName: $firstName,
                              lastName: $lastName, meetName: $meetName,
                              orgName: $orgName, meetYear: $meetYear,
                              searchSubmitted: $searchSubmitted)
            .onDisappear {
                searchSubmitted = false
            }
        } else {
            SearchInputView(selection: $selection, firstName: $firstName,
                            lastName: $lastName, meetName: $meetName,
                            orgName: $orgName, meetYear: $meetYear,
                            searchSubmitted: $searchSubmitted)
        }
    }
}

/// Currently just for testing that the results are being captured before scraping
struct SearchResultsView: View {
    @Binding var selection: SearchType
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
            if selection == .meet {
                Text(meetName)
                Text(orgName)
                Text(meetYear)
            } else {
                Text(firstName)
                Text(lastName)
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
    @Environment(\.colorScheme) var currentMode
    
    @State private var showError: Bool = false
    @Binding var selection: SearchType
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var meetName: String
    @Binding var orgName: String
    @Binding var meetYear: String
    @Binding var searchSubmitted: Bool
    private let cornerRadius: CGFloat = 30
    private let selectedBGColor: Color = Color.accentColor
    /// Light gray
    private let grayValue: CGFloat = 0.90
    private let grayValueDark: CGFloat = 0.10
    private let textColor: Color = Color.primary
//    private let deselectedTextColor: Color = Color.primary
    private let typeBubbleWidth: CGFloat = 100
    private let typeBubbleHeight: CGFloat = 35
    
    private let typeBGWidth: CGFloat = 40
    
    var body: some View {
//        let deselectedBGColor: Color = currentMode == .light
//        ? Color(red: grayValue, green: grayValue, blue: grayValue)
//        : Color(red: grayValueDark, green: grayValueDark, blue: grayValueDark)
        let typeBGColor: Color = currentMode == .light
        ? Color(red: grayValue, green: grayValue, blue: grayValue)
        : Color(red: grayValueDark, green: grayValueDark, blue: grayValueDark)
        let typeBubbleColor: Color = currentMode == .light
        ? Color.white
        : Color.black
        
        VStack {
            VStack {
                Text("Search")
                    .font(.title)
                    .bold()
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .frame(width: typeBubbleWidth * 2 + 5,
                                   height: typeBGWidth)
                            .foregroundColor(typeBGColor)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .frame(width: typeBubbleWidth,
                                   height: typeBubbleHeight)
                            .foregroundColor(typeBubbleColor)
                            .offset(x: selection == .diver
                                    ? -typeBubbleWidth / 2
                                    : typeBubbleWidth / 2)
                            .animation(.spring(response: 0.2), value: selection)
                        HStack(spacing: 0) {
                            Button(action: {
                                if selection == .meet {
                                    showError = false
                                    selection = .diver
                                }
                            }, label: {
                                Text(SearchType.diver.rawValue)
                                    .animation(nil, value: selection)
                            })
                            .frame(width: typeBubbleWidth,
                                   height: typeBubbleHeight)
                            .foregroundColor(textColor)
                            .cornerRadius(cornerRadius)
                            Button(action: {
                                if selection == .diver {
                                    showError = false
                                    selection = .meet
                                }
                            }, label: {
                                Text(SearchType.meet.rawValue)
                                    .animation(nil, value: selection)
                            })
                            .frame(width: typeBubbleWidth,
                                   height: typeBubbleHeight)
                            .foregroundColor(textColor)
//                            .background(selection == .meet
//                                        ? selectedBGColor
//                                        : deselectedBGColor)
                            .cornerRadius(cornerRadius)
                        }
                    }
//                .padding([.leading, .trailing])
            }
            
            Spacer()
            
            if selection == .meet {
                MeetSearchView(meetName: $meetName, orgName: $orgName,
                               meetYear: $meetYear)
            } else {
                DiverSearchView(firstName: $firstName, lastName: $lastName)
            }
            
            Button(action: {
                /// Only submits a search if one of the relevant fields is filled, otherwise toggles error
                if checkFields(selection: selection, firstName: firstName,
                               lastName: lastName, meetName: meetName,
                               orgName: orgName, meetYear: meetYear) {
                    searchSubmitted = true
                    showError = false
                } else {
                    showError = true
                }
            }, label: {
                Text("Submit")
                    .animation(nil, value: selection)
            })
            .buttonStyle(.bordered)
            .cornerRadius(cornerRadius)
            .animation(nil, value: selection)
            if showError {
                Text("You must enter at least one field to search")
                    .foregroundColor(Color.red)
                
            } else {
                Text("")
            }
            
            Spacer()
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
        SearchView()
    }
}
