//
//  SearchView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/2/23.
//

import SwiftUI

private enum SearchType: String, CaseIterable {
    case person = "Person"
    case meet = "Meet"
}

private enum Field: Int, Hashable, CaseIterable {
    case firstName
    case lastName
    case meetName
    case meetOrg
}

private enum FilterType: String, CaseIterable {
    case name = "Name"
    case year = "Year"
}

private extension SearchInputView {
    var hasReachedPersonStart: Bool {
        self.focusedField == Field.allCases.first
    }
    
    var hasReachedMeetStart: Bool {
        self.focusedField == Field.meetName
    }
    
    var hasReachedPersonEnd: Bool {
        self.focusedField == Field.lastName
    }
    
    var hasReachedMeetEnd: Bool {
        self.focusedField == Field.allCases.last
    }
    
    func dismissKeyboard() {
        self.focusedField = nil
    }
    
    func nextPersonField() {
        guard let currentInput = focusedField else { return }
        let lastIndex = Field.lastName.rawValue
        
        let index = min(currentInput.rawValue + 1, lastIndex)
        self.focusedField = Field(rawValue: index)
    }
    
    func nextMeetField() {
        guard let currentInput = focusedField,
              let lastIndex = Field.allCases.last?.rawValue else { return }
        
        let index = min(currentInput.rawValue + 1, lastIndex)
        self.focusedField = Field(rawValue: index)
    }
    
    func previousPersonField() {
        guard let currentInput = focusedField,
              let firstIndex = Field.allCases.first?.rawValue else { return }
        
        let index = max(currentInput.rawValue - 1, firstIndex)
        self.focusedField = Field(rawValue: index)
    }
    
    func previousMeetField() {
        guard let currentInput = focusedField else { return }
        let firstIndex = Field.meetName.rawValue
        
        let index = max(currentInput.rawValue - 1, firstIndex)
        self.focusedField = Field(rawValue: index)
    }
    
    func next() {
        if selection == .person {
            nextPersonField()
        } else {
            nextMeetField()
        }
    }
    
    func previous() {
        if selection == .person {
            previousPersonField()
        } else {
            previousMeetField()
        }
    }
}

// Checks that for a given SearchType, at least one of the relevant fields has a value, and returns true if so.
// If all relevant fields are empty, returns false
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

// Converts the arguments passed into getPredicate into the list of unpacked parameters necessary to init
// NSPredicate; returns nil if all fields are empty
private func argsToPredParams(
    pred: String, name: String, org: String, year: String) -> NSPredicate? {
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

// Produces Optional NSPredicate string based on which values are filled or not filled, returns nil if all fields
// are empty
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
    
    // Joins all the statements together with AND
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
    @Binding var isIndexingMeets: Bool
    @Binding var isFinishedCounting: Bool
    @Binding var meetsParsedCount: Int
    @Binding var totalMeetsParsedCount: Int
    private var personSearchSubmitted: Bool {
        searchSubmitted && selection == .person
    }
    private var meetSearchSubmitted: Bool {
        searchSubmitted && selection == .meet
    }
    
    @ViewBuilder
    var body: some View {
        ZStack {
            if personSearchSubmitted {
                SwiftUIWebView(firstName: $firstName, lastName: $lastName,
                               parsedLinks: $parsedLinks, dmSearchSubmitted: $dmSearchSubmitted,
                               linksParsed: $linksParsed)
            }
            
//            Color.white.ignoresSafeArea()
            
            
            SearchInputView(selection: $selection, firstName: $firstName, lastName: $lastName,
                            meetName: $meetName, orgName: $orgName, meetYear: $meetYear,
                            searchSubmitted: $searchSubmitted, parsedLinks: $parsedLinks,
                            dmSearchSubmitted: $dmSearchSubmitted, linksParsed: $linksParsed,
                            isIndexingMeets: $isIndexingMeets,
                            isFinishedCounting: $isFinishedCounting,
                            meetsParsedCount: $meetsParsedCount,
                            totalMeetsParsedCount: $totalMeetsParsedCount)
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
    // Tracks if the user is inside of a text field to determine when to show the keyboard
    @FocusState private var focusedField: Field?
    @Binding private var selection: SearchType
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var meetName: String
    @Binding var orgName: String
    @Binding var meetYear: String
    @Binding var searchSubmitted: Bool
    
    @Binding var parsedLinks: [String: String]
    @Binding var dmSearchSubmitted: Bool
    @Binding var linksParsed: Bool
    @Binding var isIndexingMeets: Bool
    @Binding var isFinishedCounting: Bool
    @Binding var meetsParsedCount: Int
    @Binding var totalMeetsParsedCount: Int
    
    @State var predicate: NSPredicate?
    @State private var filterType: FilterType = .name
    @State var isSortedAscending: Bool = true
    @FetchRequest(sortDescriptors: [])
    private var items: FetchedResults<DivingMeet>
    // Useful link:
    // https://stackoverflow.com/questions/61631611/swift-dynamicfetchview-fetchlimit/61632618#61632618
    // Updates the filteredItems value dynamically with predicate and sorting changes
    var filteredItems: FetchedResults<DivingMeet> {
        get {
            let key: String
            switch(filterType) {
                case .name:
                    key = "name"
                    break
                case .year:
                    key = "year"
                    break
            }
            _items.wrappedValue.nsSortDescriptors = [
                NSSortDescriptor(key: key, ascending: isSortedAscending)]
            _items.wrappedValue.nsPredicate = predicate
            return items
        }
    }
    
    // Light gray
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
    
    private var personResultsReady: Bool {
        selection == .person && linksParsed
    }
    private var meetResultsReady: Bool {
        selection == .meet && predicate != nil
    }
    
    fileprivate init(selection: Binding<SearchType>, firstName: Binding<String>,
                     lastName: Binding<String>, meetName: Binding<String>,
                     orgName: Binding<String>, meetYear: Binding<String>,
                     searchSubmitted: Binding<Bool>, parsedLinks: Binding<[String : String]>,
                     dmSearchSubmitted: Binding<Bool>, linksParsed: Binding<Bool>,
                     isIndexingMeets: Binding<Bool>, isFinishedCounting: Binding<Bool>,
                     meetsParsedCount: Binding<Int>, totalMeetsParsedCount: Binding<Int>) {
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
        self._isIndexingMeets = isIndexingMeets
        self._isFinishedCounting = isFinishedCounting
        self._meetsParsedCount = meetsParsedCount
        self._totalMeetsParsedCount = totalMeetsParsedCount
        self._items = FetchRequest<DivingMeet>(entity: DivingMeet.entity(),
                                               sortDescriptors: [])
    }
    
    private func clearStateFlags() {
        showError = false
        searchSubmitted = false
        dmSearchSubmitted = false
        linksParsed = false
        parsedLinks = [:]
        predicate = nil
    }
    
    private func getPercentString(count: Int, total: Int) -> String {
        return String(Int(trunc(Double(count) / Double(total) * 100)))
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
            // Allows the user to hide the keyboard when clicking on the background of the page
                .onTapGesture {
                    focusedField = nil
                }
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
                                    clearStateFlags()
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
                                    clearStateFlags()
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
                                   meetYear: $meetYear, predicate: $predicate,
                                   focusedField: $focusedField, items: filteredItems)
                } else {
                    DiverSearchView(firstName: $firstName, lastName: $lastName,
                                    focusedField: $focusedField)
                }
                
                VStack {
                    Button(action: {
                        // Need to initially set search to false so webView gets recreated
                        searchSubmitted = false
                        
                        // Resets focusedField so keyboard disappears
                        focusedField = nil
                        
                        // Only submits a search if one of the relevant fields is filled,
                        // otherwise toggles error
                        if checkFields(selection: selection, firstName: firstName,
                                       lastName: lastName, meetName: meetName,
                                       orgName: orgName, meetYear: meetYear) {
                            clearStateFlags()
                            searchSubmitted = true
                            
                            if selection == .meet {
                                predicate = getPredicate(name: meetName, org: orgName,
                                                         year: meetYear)
                            }
                        } else {
                            clearStateFlags()
                            showError = true
                        }
                    }, label: {
                        Text("Submit")
                            .animation(nil, value: selection)
                    })
                    .buttonStyle(.bordered)
                    .cornerRadius(cornerRadius)
                    .animation(nil, value: selection)
                    if selection == .person && searchSubmitted && !linksParsed {
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
                
                if selection == .meet && isIndexingMeets {
                    VStack {
                        // Displays loading bar if counts are done, otherwise shows indefinite
                        // progress bar
                        Group {
                            if isFinishedCounting {
                                VStack(alignment: .leading) {
                                    Text("Indexing...")
                                        .font(.headline)
                                        .padding(.leading)
                                    ProgressView(value: Double(meetsParsedCount),
                                                 total: Double(totalMeetsParsedCount))
                                    .progressViewStyle(.linear)
                                    .frame(width: 250)
                                    .padding(.leading)
                                    Text(getPercentString(count: meetsParsedCount,
                                                          total: totalMeetsParsedCount) + "%")
                                    .foregroundColor(.gray)
                                    .padding(.leading)
                                }
                            } else {
                                VStack {
                                    Text("Indexing...")
                                        .font(.headline)
                                        .padding(.leading)
                                    ProgressView()
                                }
                            }
                        }
                        .padding(.bottom)
                        Text("Some results may not appear in Search yet")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
                Spacer()
                Spacer()
            }
            // Keyboard toolbar with up/down arrows and Done button
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: previous) {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(hasReachedPersonStart || hasReachedMeetStart)
                    
                    Button(action: next) {
                        Image(systemName: "chevron.down")
                    }
                    .disabled(hasReachedPersonEnd || hasReachedMeetEnd)
                    
                    Spacer()
                    
                    Button(action: dismissKeyboard) {
                        Text("**Done**")
                    }
                }
            }
            
            if personResultsReady || meetResultsReady {
                ZStack (alignment: .topLeading) {
                    (selection == .person
                     ? AnyView(RecordList(records: $parsedLinks,
                                          resultSelected: $resultSelected))
                     : AnyView(MeetResultsView(records: filteredItems)))
                    .onAppear {
                        fullScreenResults = true
                    }
                    if !resultSelected {
                        Button(action: { () -> () in fullScreenResults.toggle() }) {
                            Image(systemName: "chevron.down")
                        }
                        .rotationEffect(.degrees(fullScreenResults ? 0: -180))
                        .frame(width:50, height: 50)
                        .foregroundColor(.primary)
                        .font(.system(size: 22))
                        .contentShape(Rectangle())
                    }
                    HStack {
                        Spacer()
                        Menu {
                            Picker("", selection: $filterType) {
                                ForEach(FilterType.allCases, id: \.self) {
                                    Text($0.rawValue)
                                        .tag($0)
                                }
                            }
                            Button(action: { () -> () in isSortedAscending.toggle() }) {
                                Label("Sort: \(isSortedAscending ? "Ascending" : "Descending")",
                                      systemImage: "arrow.up.arrow.down")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        .frame(width: 50, height: 50)
                        .foregroundColor(.primary)
                        .font(.system(size: 22))
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
    fileprivate var focusedField: FocusState<Field?>.Binding
    
    var body: some View {
        VStack {
            HStack {
                Text("First Name:")
                    .padding(.leading)
                TextField("First Name", text: $firstName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing)
                    .focused(focusedField, equals: .firstName)
            }
            HStack {
                Text("Last Name:")
                    .padding(.leading)
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing)
                    .focused(focusedField, equals: .lastName)
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
    private var focusedField: FocusState<Field?>.Binding
    private var filteredItems: FetchedResults<DivingMeet>
    
    fileprivate init(meetName: Binding<String>, orgName: Binding<String>,
                     meetYear: Binding<String>, predicate: Binding<NSPredicate?>,
                     focusedField: FocusState<Field?>.Binding, items: FetchedResults<DivingMeet>) {
        self._meetName = meetName
        self._orgName = orgName
        self._meetYear = meetYear
        self._predicate = predicate
        self.focusedField = focusedField
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
                    .focused(focusedField, equals: .meetName)
            }
            HStack {
                Text("Organization Name:")
                    .padding(.leading)
                TextField("Organization Name", text: $orgName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing)
                    .focused(focusedField, equals: .meetOrg)
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
