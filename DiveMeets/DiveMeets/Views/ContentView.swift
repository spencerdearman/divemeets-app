//
//  ContentView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/1/23.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .house
    
    /*
     * Unclear if this init is necessary
     */
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack {
            VStack{
                TabView(selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.rawValue) { tab in
                        HStack {
                            /*
                             * Add different page views here for different tabs
                             */
                            switch tab {
                                case .house:
                                    ProfileView()
                                case .gearshape:
                                    Image(systemName: tab.rawValue)
                                case .magnifyingglass:
                                    Text("\(tab.rawValue.capitalized)")
                                        .bold()
                                        .animation(nil, value: selectedTab)
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
