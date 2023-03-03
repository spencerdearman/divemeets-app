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
}

struct FloatingMenuBar: View {
    @Binding var selectedTab: Tab
    private let selectedColor: Color = .black
    private let deselectedColor: Color = .gray
    private let cornerRadius: CGFloat = 20
    private let frameHeight: CGFloat = 60
    
    /// Add custom multipliers for selected tabs here, defaults to 1.25
    private let sizeMults: [String: Double] = [
        "magnifyingglass": 1.5
    ]
    
    private var fillImage: String {
        selectedTab.rawValue == "magnifyingglass"
        ? selectedTab.rawValue + ".circle.fill"
        : selectedTab.rawValue + ".fill"
    }
    
    var body: some View {
        VStack {
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
            .frame(width: nil, height: frameHeight)
            .background(.thinMaterial)
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
