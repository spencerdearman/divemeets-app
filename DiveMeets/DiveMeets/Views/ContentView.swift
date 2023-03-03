//
//  ContentView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/1/23.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .house
    @State var hideTabBar = false
    
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
                                    ProfileView(hideTabBar: $hideTabBar)
                                case .gearshape:
                                    Image(systemName: tab.rawValue)
                                    Text("Settings")
                                        .bold()
                                        .animation(nil, value: selectedTab)
                                case .magnifyingglass:
                                    SearchView()
                            }
                        }
                        .tag(tab)
                        
                    }
                }
            }
            
            VStack {
                Spacer()
                FloatingMenuBar(selectedTab: $selectedTab)
            }
            .offset(y: hideTabBar ? 110 : 20)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
