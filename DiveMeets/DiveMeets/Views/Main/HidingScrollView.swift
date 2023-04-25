//
//  HidingScrollView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/2/23.
//

import SwiftUI

struct HidingScrollView: View {
    // Include for hiding/showing tab bar
    @Binding var hideTabBar: Bool
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    // End of include
    
    private let animationSpeed: CGFloat = 1.25
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                ForEach(1..<100) {i in
                    Text("Item \(i)")
                    Spacer()
                }
            }
            // Addition to VStack to track scrolling for hiding tab bar
            .overlay(
                
                GeometryReader {proxy -> Color in
                    
                    let minY = proxy.frame(in: .named("SCROLL")).minY
                    
                    /// Duration to hide TabBar
                    let durationOffset: CGFloat = 0
                    
                    /// Runs in the background and checks for changes in Y from scrolling up/down
                    DispatchQueue.main.async {
                        if minY < offset {
                            if offset < 0 && -minY > (lastOffset + durationOffset) {
                                withAnimation(.easeOut.speed(animationSpeed)) {
                                    hideTabBar = true
                                }
                                lastOffset = -offset
                            }
                        }
                        if offset < minY {
                            if offset < 0 && -minY < (lastOffset - durationOffset) {
                                withAnimation(.easeIn.speed(animationSpeed)) {
                                    hideTabBar = false
                                }
                                lastOffset = -offset
                            }
                        }
                        
                        self.offset = minY
                    }
                    
                    return Color.clear
                }
                
            )
            .padding()
        }
        .coordinateSpace(name: "SCROLL")
        // End of addition for tab bar
    }
}

struct HidingScrollView_Previews: PreviewProvider {
    static var previews: some View {
        HidingScrollView(hideTabBar: .constant(false))
    }
}
