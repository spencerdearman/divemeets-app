//
//  SplashView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 6/24/23.
//

import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) var currentMode
    @Binding var showSplash: Bool
    @Namespace var namespace
    
    private let shadowRadius: CGFloat = 15
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    var body: some View {
        ZStack {
            ZStack {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let midX = width / 2
                    let midY = height / 2
                    let imgSize = width * 0.4
                    let xxxsmall = width * 0.7
                    let xxsmall = width * 0.8
                    let xsmall = width * 0.9
                    let small = width * 1.5
                    let med = width * 2.0
                    let large = width * 2.5
                    
                    if !showSplash {
                        bgColor.ignoresSafeArea()
                            .opacity(0.0)
                            .matchedGeometryEffect(id: "bg", in: namespace)
                        
                        Circle()
                            .fill(Custom.darkBlue) // Circle color
                            .shadow(radius: shadowRadius)
                            .zIndex(0)
                            .matchedGeometryEffect(id: "sphere1", in: namespace)
                            .position(x: midX, y: height * 1.68)
                            // Adjust the size of the circle as desired
                            .frame(width: large, height: large)
                        Circle()
                            .fill(Custom.coolBlue) // Circle color
                            .shadow(radius: shadowRadius)
                            .zIndex(1)
                            .matchedGeometryEffect(id: "sphere2", in: namespace)
                            .position(x: midX, y: -height * 0.59)
                            .frame(width: med, height: med)
                        Circle()
                            .fill(Custom.medBlue) // Circle color
                            .shadow(radius: shadowRadius)
                            .zIndex(2)
                            .matchedGeometryEffect(id: "sphere3", in: namespace)
                            .position(x: width * 1.5, y: -height * 0.35)
                            .frame(width: small, height: small)
                        Image("defaultImage")
                            .resizable()
                            .scaledToFit()
                            .zIndex(-1)
                            .matchedGeometryEffect(id: "icon", in: namespace)
                            .position(x: -width * 0.15, y: -height * 0.13)
                            .frame(width: imgSize)
                    } else {
                        bgColor.ignoresSafeArea()
                            .matchedGeometryEffect(id: "bg", in: namespace)
                        
                        Circle()
                            .fill(Custom.darkBlue) // Circle color
                            .shadow(radius: shadowRadius)
                            .zIndex(0)
                            .matchedGeometryEffect(id: "sphere1", in: namespace)
                            .position(x: midX, y: midY) // Center the circle
                            // Adjust the size of the circle as desired
                            .frame(width: xsmall, height: xsmall)
                        Circle()
                            .fill(Custom.coolBlue) // Circle color
                            .shadow(radius: shadowRadius)
                            .zIndex(1)
                            .matchedGeometryEffect(id: "sphere2", in: namespace)
                            .position(x: midX, y: midY) // Center the circle
                            .frame(width: xxsmall, height: xxsmall)
                        Circle()
                            .fill(Custom.medBlue) // Circle color
                            .shadow(radius: shadowRadius)
                            .zIndex(2)
                            .matchedGeometryEffect(id: "sphere3", in: namespace)
                            .position(x: midX, y: midY) // Center the circle
                            .frame(width: xxxsmall, height: xxxsmall)
                        
                        Image("defaultImage")
                            .resizable()
                            .scaledToFit()
                            .zIndex(3)
                            .matchedGeometryEffect(id: "icon", in: namespace)
                            .position(x: midX, y: midY)
                            .frame(width: imgSize)
                    }
                }
            }
        }
        .zIndex(100)
    }
}
