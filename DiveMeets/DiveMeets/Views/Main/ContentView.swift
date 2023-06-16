//
//  ContentView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/1/23.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.meetsDB) var db
    @EnvironmentObject private var p: MeetParser
    @State private var selectedTab: Tab = .house
    @State var isIndexingMeets: Bool = false
    @FetchRequest(sortDescriptors: []) private var meets: FetchedResults<DivingMeet>
    
    var hasHomeButton: Bool {
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            guard let window = windowScene?.windows.first else { return false }
            
            return !(window.safeAreaInsets.top > 20)
        }
    }
    
    var menuBarOffset: CGFloat {
        hasHomeButton ? 0 : 20
    }
    
    // Necessary to hide gray navigation bar from behind floating tab bar
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack {
            VStack {
                TabView(selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.rawValue) { tab in
                        HStack {
                            // Add different page views here for different tabs
                            switch tab {
                            case .house:
                                Home()
                            case .gearshape:
//                                Image(systemName: tab.rawValue)
//                                Text("Settings")
//                                    .bold()
//                                    .animation(nil, value: selectedTab)
                                    MeetPageView(meetLink: "https://secure.meetcontrol.com/divemeets/system/meetresultsext.php?meetnum=8958")
                            case .magnifyingglass:
                                SearchView(isIndexingMeets: $isIndexingMeets)
                            case .person:
                                LoginSearchView()
                            }
                        }
                        .tag(tab)
                        
                    }
                }
            }
            
            FloatingMenuBar(selectedTab: $selectedTab)
                .offset(y: menuBarOffset)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea(.keyboard)
        // Executes on app launch
        .onAppear {
            // isIndexingMeets is set to false by default so it is only executed from start
            //     to finish one time (allows indexing to occur in the background without
            //     starting over)
            if !isIndexingMeets {
                isIndexingMeets = true
                
                // Runs this task asynchronously so rest of app can function while this finishes
                Task {
                    // This sets p's upcoming, current, and past meets fields
                    try await p.parseMeets(storedMeets: meets)
                    
                    // Check that each set of meets is not nil and add each to the database
                    if let upcoming = p.upcomingMeets {
                        db.addRecords(records: db.dictToTuple(dict: upcoming), type: .upcoming)
                    }
                    if let current = p.currentMeets {
                        db.addRecords(records: db.dictToTuple(dict: current), type: .current)
                    }
                    if let past = p.pastMeets {
                        db.addRecords(records: db.dictToTuple(dict: past), type: .past)
                    }
                    
                    isIndexingMeets = false
                }
            }
        }
        // Executes when other views are opened (notification center, control center, swiped up)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                GlobalCaches.loadAllCaches()
            } else if scenePhase == .active && newPhase == .inactive {
                GlobalCaches.saveAllCaches()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            ContentView().preferredColorScheme($0)
        }
    }
}
