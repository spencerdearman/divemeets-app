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
    @State private var selectedTab: Tab = .magnifyingglass
    @State var hideTabBar = false
    @State var visibleTabs: [Tab] = Tab.allCases
    @State var isIndexingMeets: Bool = false
    @StateObject private var getTextModel = GetTextAsyncModel()
    @State private var p: MeetParser = MeetParser()
    @FetchRequest(sortDescriptors: []) private var meets: FetchedResults<DivingMeet>
    
    // Necessary to hide gray navigation bar from behind floating tab bar
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack {
            VStack{
                TabView(selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.rawValue) { tab in
                        HStack {
                            // Add different page views here for different tabs
                            switch tab {
                                case .house:
                                    ProfileView(hideTabBar: $hideTabBar, link:"", diverID: "51197")
                                case .gearshape:
                                    Image(systemName: tab.rawValue)
                                    Text("Settings")
                                        .bold()
                                        .animation(nil, value: selectedTab)
                                case .magnifyingglass:
                                    SearchView(hideTabBar: $hideTabBar,
                                               isIndexingMeets: $isIndexingMeets,
                                               isFinishedCounting: $p.isFinishedCounting,
                                               meetsParsedCount: $p.meetsParsedCount,
                                               totalMeetsParsedCount: $p.totalMeetsParsedCount)
                                case .person:
                                LoginSearchView(hideTabBar: $hideTabBar)
                            }
                        }
                        .tag(tab)
                        
                    }
                }
            }
            Group {
                VStack {
                    Spacer()
                    FloatingMenuBar(selectedTab: $selectedTab,
                                    hideTabBar: $hideTabBar,
                                    visibleTabs: $visibleTabs)
                    .offset(y: hideTabBar ? 110 : 20)
                    .animation(.spring(), value: hideTabBar)
                }
                
                // Safe area tap to retrieve hidden tab bar
                if hideTabBar {
                    Rectangle()
                        .foregroundColor(Color.clear)
                        .contentShape(Rectangle())
                        .frame(width: 150, height: 90)
                        .offset(y: 370)
                        .onTapGesture { _ in
                            hideTabBar = false
                            
                            // Adds delay for menu bar to grow to full size after
                            // a change
                            DispatchQueue.main.asyncAfter(
                                deadline: (
                                    DispatchTime.now() + menuBarHideDelay)
                            ) {
                                visibleTabs = Tab.allCases
                            }
                        }
                    
                }
            }
            // Keeps keyboard from pushing menu bar up the page when it appears
            .ignoresSafeArea(.keyboard)
        }
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
                        db.addRecords(records: db.dictToTuple(dict: upcoming))
                    }
                    if let current = p.currentMeets {
                        db.addRecords(records: db.dictToTuple(dict: current))
                    }
                    if let past = p.pastMeets {
                        db.addRecords(records: db.dictToTuple(dict: past))
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
