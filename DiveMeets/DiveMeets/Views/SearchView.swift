//
//  SearchView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/2/23.
//

import SwiftUI

enum SearchType: String, CaseIterable {
    case person = "Person"
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

/// Converts the arguments passed into getPredicate into the list of unpacked parameters necessary to init
/// NSPredicate; returns nil if all fields are empty
private func argsToPredParams(pred: String, name: String, org: String, year: String) -> NSPredicate? {
    let haveName = name != ""
    let haveOrg = org != ""
    let haveYear = year != ""
    var castYear: Int16? = nil
    
    if haveYear {
        castYear = Int16(year)!
    }
    
    if haveName && haveOrg && haveYear {
        return NSPredicate(format: pred, name, org, castYear!)
    } else if haveName && haveOrg {
        return NSPredicate(format: pred, name, org)
    } else if haveName && haveYear {
        return NSPredicate(format: pred, name, castYear!)
    } else if haveOrg && haveYear {
        return NSPredicate(format: pred, org, castYear!)
    } else if haveName {
        return NSPredicate(format: pred, name)
    } else if haveOrg {
        return NSPredicate(format: pred, org)
    } else if haveYear {
        return NSPredicate(format: pred, castYear!)
    }
    
    return nil
}

/// Produces Optional NSPredicate string based on which values are filled or not filled, returns nil if all fields
/// are empty
private func getPredicate(name: String, org: String, year: String) -> NSPredicate? {
    if name == "" && org == "" && year == "" {
        return nil
    }
    
    var subqueries: [String] = []
    
    if name != "" {
        subqueries.append("%@ in[cd] name")
    }
    
    if org != "" {
        subqueries.append("%@ in[cd] organization")
    }
    
    if year != "" {
        subqueries.append("year == %d")
    }
    
    var resultString: String = ""
    
    /// Joins all the statements together with AND
    for (idx, query) in subqueries.enumerated() {
        resultString += query
        if idx < subqueries.count - 1 {
            resultString += " AND "
        }
    }
    
    return argsToPredParams(pred: resultString, name: name, org: org, year: year)
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

struct SearchInputView: View {
    @Environment(\.colorScheme) var currentMode
    
    @State private var showError: Bool = false
    @State var fullScreenResults: Bool = false
    @State var resultSelected: Bool = false
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
    
    @State var predicate: NSPredicate?
    @FetchRequest private var items: FetchedResults<DivingMeet>
    // Updates the filteredItems value dynamically with predicate changes
    var filteredItems: FetchedResults<DivingMeet> {
        get {
            _items.wrappedValue.nsPredicate = predicate
            return items
        }
    }
    
    /// Light gray
    private let deselectedBGColor: Color = Color(red: 0.94, green: 0.94,
                                                 blue: 0.94)
    private let selectedTextColor: Color = Color.white
    private let deselectedTextColor: Color = Color.blue
    
    private let cornerRadius: CGFloat = 30
    private let selectedBGColor: Color = Color.accentColor
    private let grayValue: CGFloat = 0.90
    private let grayValueDark: CGFloat = 0.10
    private let textColor: Color = Color.primary
    private let typeBubbleWidth: CGFloat = 100
    private let typeBubbleHeight: CGFloat = 35
    
    private let typeBGWidth: CGFloat = 40
    
    init(selection: Binding<SearchType>, firstName: Binding<String>, lastName: Binding<String>, meetName: Binding<String>, orgName: Binding<String>, meetYear: Binding<String>, searchSubmitted: Binding<Bool>, parsedLinks: Binding<[String : String]>, dmSearchSubmitted: Binding<Bool>, linksParsed: Binding<Bool>, hideTabBar: Binding<Bool>) {
        self._selection = selection
        self._firstName = firstName
        self._lastName = lastName
        self._meetName = meetName
        self._orgName = orgName
        self._meetYear = meetYear
        self._searchSubmitted = searchSubmitted
        self._parsedLinks = parsedLinks
        self._dmSearchSubmitted = dmSearchSubmitted
        self._linksParsed = linksParsed
        self._hideTabBar = hideTabBar
        self._items = FetchRequest<DivingMeet>(entity: DivingMeet.entity(), sortDescriptors: [])
    }
    
    private func clearTypeFlags() {
        showError = false
        resultSelected = false
        searchSubmitted = false
        dmSearchSubmitted = false
        linksParsed = false
        parsedLinks = [:]
        predicate = nil
    }
    
    var body: some View {
        let typeBGColor: Color = currentMode == .light
        ? Color(red: grayValue, green: grayValue, blue: grayValue)
        : Color(red: grayValueDark, green: grayValueDark, blue: grayValueDark)
        let typeBubbleColor: Color = currentMode == .light
        ? Color.white
        : Color.black
        
        ZStack {
            typeBubbleColor
                .ignoresSafeArea()
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
                            .offset(x: selection == .person
                                    ? -typeBubbleWidth / 2
                                    : typeBubbleWidth / 2)
                            .animation(.spring(response: 0.2), value: selection)
                        HStack(spacing: 0) {
                            Button(action: {
                                if selection == .meet {
                                    clearTypeFlags()
                                    selection = .person
                                }
                            }, label: {
                                Text(SearchType.person.rawValue)
                                    .animation(nil, value: selection)
                            })
                            .frame(width: typeBubbleWidth,
                                   height: typeBubbleHeight)
                            .foregroundColor(textColor)
                            .cornerRadius(cornerRadius)
                            Button(action: {
                                if selection == .person {
                                    clearTypeFlags()
                                    selection = .meet
                                }
                            }, label: {
                                Text(SearchType.meet.rawValue)
                                    .animation(nil, value: selection)
                            })
                            .frame(width: typeBubbleWidth,
                                   height: typeBubbleHeight)
                            .foregroundColor(textColor)
                            .cornerRadius(cornerRadius)
                        }
                    }
                }
                
                if selection == .meet {
                    MeetSearchView(meetName: $meetName, orgName: $orgName,
                                   meetYear: $meetYear, predicate: $predicate, items: filteredItems)
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
                            clearTypeFlags()
                            searchSubmitted = true
                            
                            if selection == .meet {
                                predicate = getPredicate(name: meetName, org: orgName, year: meetYear)
                                print(predicate ?? "nil")
                            }
                        } else {
                            clearTypeFlags()
                            showError = true
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
                
                Spacer()
                Spacer()
                Spacer()
            }
            
            if (selection == .person && linksParsed)
                || (selection == .meet && predicate != nil) {
                ZStack (alignment: .topLeading) {
                    (selection == .person ? AnyView(RecordList(hideTabBar: $hideTabBar, records: $parsedLinks, resultSelected: $resultSelected)) : AnyView(MeetResultsView(records: filteredItems)))
                        .onAppear {
                            fullScreenResults = true
                        }
                    if !resultSelected {
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(fullScreenResults ? 0: 180))
                            .frame(width:50, height: 50)
                            .foregroundColor(.black)
                            .font(.system(size: 22))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                fullScreenResults.toggle()
                            }
                    }
                }
                .offset(y: fullScreenResults ? 0 : 350)
                .animation(.linear(duration: 0.2), value: fullScreenResults)
            }
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
    @Binding private var predicate: NSPredicate?
    private var filteredItems: FetchedResults<DivingMeet>
    
    init(meetName: Binding<String>, orgName: Binding<String>, meetYear: Binding<String>,
         predicate: Binding<NSPredicate?>, items: FetchedResults<DivingMeet>) {
        self._meetName = meetName
        self._orgName = orgName
        self._meetYear = meetYear
        self._predicate = predicate
        self.filteredItems = items
    }
    
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
                    Text("").tag("")
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

struct MeetResultsView : View {
    @Environment(\.colorScheme) var currentMode
    var records: FetchedResults<DivingMeet>
    private let grayValue: CGFloat = 0.95
    private let grayValueDark: CGFloat = 0.10
    
    var body: some View {
        let gray = currentMode == .light ? grayValue : grayValueDark
        ZStack {
            Color(red: gray, green: gray, blue: gray)
                .ignoresSafeArea()
            VStack(alignment: .leading) {
                
                Text("Results")
                    .bold()
                    .font(.largeTitle)
                    .foregroundColor(.primary)
                    .padding(.leading, 20)
                    .padding(.top, 50)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !records.isEmpty {
                    List(records) { result in
                        Button(result.name!) {
                            print(result.link!)
                        }
                        .foregroundColor(.primary)
                    }
                    .offset(y: -50)
                    .scrollContentBackground(.hidden)
                }
                Spacer()
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            SearchView(hideTabBar: .constant(false)).preferredColorScheme($0)
        }
    }
}
