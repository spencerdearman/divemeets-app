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
    return -1
}

struct FloatingMenuBar: View {
    @Binding var selectedTab: Tab
    private let selectedColor: Color = .white
    private let deselectedColor: Color = .gray
    private let selectedBubbleColor: Color = .black
    private let deselectedBubbleColor: Color = .clear
    private let cornerRadius: CGFloat = 50
    private let frameHeight: CGFloat = 60
    private let padding: CGFloat = 48
    
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
                let geoWidth: CGFloat = geometry.size.width
                let tabWidth: CGFloat = ((geoWidth - padding) /
                                         CGFloat(Tab.allCases.count))
                ZStack {
                    /// Clear background of menu bar
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                        .frame(width: geoWidth, height: frameHeight)
                    /// Moving bubble on menu bar
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(selectedBubbleColor)
                        .frame(width: tabWidth, height: frameHeight)
                        .offset(x: selectedXOffset(from: tabWidth))
                        .animation(.spring(), value: selectedTab)
                    /// Line of buttons for each tab
                    HStack {
                        ForEach(Tab.allCases, id: \.rawValue) { tab in
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
                            .onTapGesture() {
                                withAnimation(.easeIn(duration: 0.1)) {
                                    selectedTab = tab
                                }
                            }
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
        FloatingMenuBar(selectedTab: .constant(.house))
    }
}
