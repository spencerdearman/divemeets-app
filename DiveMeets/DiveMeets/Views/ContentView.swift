//
//  ContentView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/1/23.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var currentMode
    
    @State private var selectedTab: Tab = .house
    @State var hideTabBar = false
    @State var visibleTabs: [Tab] = Tab.allCases
    
    /// Necessary to hide gray navigation bar from behind floating tab bar
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack {
            VStack{
                TabView(selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.rawValue) { tab in
                        HStack {
                            /// Add different page views here for different tabs
                            switch tab {
                                case .house:
                                    Image(systemName: tab.rawValue)
                                    Text("Home")
                                        .bold()
                                        .animation(nil, value: selectedTab)
                                case .magnifyingglass:
                                    SearchView()
                                case .person:
                                    ProfileView(hideTabBar: $hideTabBar)
                            }
                        }
                        .tag(tab)
                        
                    }
                }
            }
            VStack {
                Spacer()
                FloatingMenuBar(selectedTab: $selectedTab,
                                hideTabBar: $hideTabBar,
                                visibleTabs: $visibleTabs)
                .offset(y: hideTabBar ? 110 : 20)
                .animation(.spring(), value: hideTabBar)
            }
            
            /// Safe area tap to retrieve hidden tab bar
            if hideTabBar {
                Rectangle()
                    .foregroundColor(Color.clear)
                    .contentShape(Rectangle())
                    .frame(width: 150, height: 90)
                    .offset(y: 370)
                    .onTapGesture { _ in
                        hideTabBar = false
                        
                        /// Adds delay for menu bar to grow to full size after
                        /// a change
                        DispatchQueue.main.asyncAfter(
                            deadline: (
                                DispatchTime.now() + menuBarHideDelay)
                        ) {
                            visibleTabs = Tab.allCases
                        }
                    }
                
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
