//
//  FloatingMenuBar.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 2/28/23.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case house
    case gearshape
    case magnifyingglass
    //    case person
    //    case eraser
}

func IntFromTab(_ t: Tab) -> Int {
    var i: Int = 0
    for e in Tab.allCases {
        if e == t {
            return i
        }
        i += 1
    }
    /// This should not be possible to reach since t is a Tab and we are iterating over all Tabs, so it will
    /// always reach the inner if statement and return
    return -1
}

struct FloatingMenuBar: View {
    @State private var visibleTabs: [Tab] = Tab.allCases
    @Binding var selectedTab: Tab
    @Binding var hideTabBar: Bool
    private let selectedColor: Color = .white
    private let deselectedColor: Color = .gray
    private let selectedBubbleColor: Color = .black
    private let deselectedBubbleColor: Color = .clear
    private let cornerRadius: CGFloat = 50
    private let frameHeight: CGFloat = 60
    private let padding: CGFloat = 48
    private let menuBarExpandDelay: CGFloat = 3
    private let menuBarHideDelay: CGFloat = 1
    
    /// Add custom multipliers for selected tabs here, defaults to 1.25
    private let sizeMults: [String: Double] = [
        "magnifyingglass": 1.5
    ]
    
    private var fillImage: String {
        selectedTab.rawValue == "magnifyingglass"
        ? selectedTab.rawValue + ".circle.fill"
        : selectedTab.rawValue + ".fill"
    }
    
    /// This is not that great, doesn't work perfectly beyond 3 icons
    private func selectedXOffset(from tabWidth: CGFloat) -> CGFloat {
        let dynamicPad: CGFloat = padding / CGFloat(Tab.allCases.count)
        let tabInt: CGFloat = CGFloat(IntFromTab(selectedTab))
        let casesCount: Int = Tab.allCases.count
        /// Sets midpoint to middle icon index, chooses left of middle if even num of
        /// choices
        var menuBarMidpoint: CGFloat {
            casesCount.isMultiple(of: 2)
            ? (CGFloat(casesCount)) / 2 - 1
            : floor(CGFloat(casesCount) / 2)
        }
        let enumOffset: CGFloat = tabInt - menuBarMidpoint
        
        if casesCount.isMultiple(of: 2) {
            return ((tabWidth + dynamicPad) * enumOffset -
                    (tabWidth + dynamicPad / 2) / 2)
        } else {
            return (tabWidth + dynamicPad) * enumOffset
        }
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                /// Width of menu bar
                let geoWidth: CGFloat =
                visibleTabs.count > 1
                ? geometry.size.width
                : cornerRadius * 1.2
                
                /// Width of bubble for one tab
                let tabWidth: CGFloat =
                visibleTabs.count > 1
                ? ((geoWidth - padding) /
                   CGFloat(Tab.allCases.count))
                : geoWidth
                
                /// x offset from center of tab bar to selected tab
                let xOffset: CGFloat =
                visibleTabs.count > 1
                ? selectedXOffset(from: tabWidth)
                : 0
                
                ZStack {
                    /// Clear background of menu bar
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                        .frame(width: geoWidth, height: frameHeight)
                        .animation(.spring(), value: visibleTabs)
                    /// Moving bubble on menu bar
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(selectedBubbleColor)
                        .frame(width: tabWidth, height: frameHeight)
                        .offset(x: xOffset)
                        .animation(.spring(), value: visibleTabs)
                        .animation(.spring(), value: selectedTab)
                    /// Line of buttons for each tab
                    HStack {
                        ForEach(visibleTabs, id: \.rawValue) { tab in
                            Spacer()
                            Image(systemName: selectedTab == tab
                                  ? fillImage
                                  : tab.rawValue)
                            .scaleEffect(tab == selectedTab
                                         ? sizeMults[tab.rawValue] ?? 1.25
                                         : 1.0)
                            .foregroundColor(selectedTab == tab
                                             ? selectedColor
                                             : deselectedColor)
                            .font(.system(size: 22))
                            /// Adds tab change and visible tabs change on button press
                            .onTapGesture() {
                                withAnimation(.spring()) {
                                    selectedTab = tab
                                    visibleTabs = [tab]
                                    
                                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + menuBarHideDelay) {
                                        hideTabBar = true
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + menuBarHideDelay + menuBarExpandDelay) {
                                        hideTabBar = false
                                    }
                                    
                                    /// Adds delay for menu bar to grow to full size after
                                    /// a change
                                    DispatchQueue.main.asyncAfter(
                                        deadline: (
                                            DispatchTime.now() + menuBarHideDelay + menuBarExpandDelay
                                            + menuBarHideDelay)
                                    ) {
                                        visibleTabs = Tab.allCases
                                    }
                                }
                            }
                            /// Animation for icon to move after menu bar changes
                            .animation(.spring(), value: visibleTabs)
                            Spacer()
                        }
                    }
                }
            }
            .frame(height: frameHeight)
            .cornerRadius(cornerRadius)
            .padding()
        }
    }
}

struct FloatingMenuBar_Previews: PreviewProvider {
    static var previews: some View {
        FloatingMenuBar(selectedTab: .constant(.house), hideTabBar: .constant(false))
    }
}
