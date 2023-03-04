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
    
    /// Add custom multipliers for selected tabs here, defaults to 1.25
    private let sizeMults: [String: Double] = [
        "magnifyingglass": 1.5
    ]
    
    private var fillImage: String {
        selectedTab.rawValue == "magnifyingglass"
        ? selectedTab.rawValue + ".circle.fill"
        : selectedTab.rawValue + ".fill"
    }
    
    private func selectionBarXOffset(from totalWidth: CGFloat) -> CGFloat {
        return self.tabWidth(from: totalWidth) * CGFloat(IntFromTab(selectedTab))
    }
    
    private func tabWidth(from totalWidth: CGFloat) -> CGFloat {
        return totalWidth / CGFloat(Tab.allCases.count)
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let geoWidth: CGFloat = geometry.size.width - 16
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(selectedBubbleColor)
                        .frame(width: self.tabWidth(from: geoWidth - 64), height: frameHeight, alignment: .leading)
                        .offset(x: self.selectionBarXOffset(from: geoWidth), y: -100)
                        .animation(.spring(), value: selectedTab)
                        .padding()
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.clear)
                        .frame(width: geoWidth, height: frameHeight, alignment: .leading)
                        .padding()
                }.fixedSize(horizontal: false, vertical: true)
            }.fixedSize(horizontal: false, vertical: true)
            HStack {
                ForEach(Tab.allCases, id: \.rawValue) { tab in
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .foregroundColor(selectedTab == tab ? Color.black : Color.clear)
                            .frame(width: nil, height: frameHeight)
                            .animation(.linear, value: tab)
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
