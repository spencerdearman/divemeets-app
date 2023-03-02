//
//  HidingScrollView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/2/23.
//

import SwiftUI

struct HidingScrollView: View {
    @Binding var hideTabBar: Bool
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                ForEach(1..<100) {i in
                    Text("Item \(i)")
                    Spacer()
                }
            }
            .overlay(
            
                GeometryReader {proxy -> Color in
                    
                    let minY = proxy.frame(in: .named("SCROLL")).minY
                    
                    /*
                     * Duration to hide TabBar
                     */
                    let durationOffset: CGFloat = 0
                    
                    DispatchQueue.main.async {
                        if minY < offset {
                            print("down")
                            
                            if offset < 0 && -minY > (lastOffset + durationOffset) {
                                withAnimation(.easeOut.speed(1.5)) {
                                    hideTabBar = true
                                }
                                lastOffset = -offset
                            }
                        }
                        if offset < minY {
                            print("up")
                            
                            if offset < 0 && -minY < (lastOffset - durationOffset) {
                                withAnimation(.easeIn.speed(1.5)) {
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
    }
}

struct HidingScrollView_Previews: PreviewProvider {
    static var previews: some View {
        HidingScrollView(hideTabBar: .constant(false))
    }
}
