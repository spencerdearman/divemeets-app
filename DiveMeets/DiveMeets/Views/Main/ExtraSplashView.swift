//
//  ExtraSplashView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 6/27/23.
//

import SwiftUI

// Transition starts as idle, moves to bottom of screen, then away to top
enum MoveStage: Int, CaseIterable {
    case idle = 0
    case bottom = 1
    case top = 2
}

struct ExtraSplashView: View {
    @Environment(\.colorScheme) var currentMode
    @State var showSplash: Bool = true
    @State var moveStage: MoveStage = .idle
    @State var sphereMoving: [Bool] = [false, false, false, false]
    @Namespace var namespace
    
    private let shadowRadius: CGFloat = 15
    private let moveSeparation: CGFloat = 0.02
    private let delayToTop: CGFloat = 0.4
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            ZStack {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let midX = width / 2
                    let midY = height / 2
                    let imgSize = width * 0.4
                    let imgBig = width * 0.6
                    let xxxsmall = width * 0.7
                    let xxsmall = width * 0.8
                    let xsmall = width * 0.9
                    let small = width * 1.5
                    let med = width * 2.0
                    let large = width * 2.5
                    let bottomPos = height * 0.8
                    let largeCircle = Circle()
                        .fill(Custom.darkBlue) // Circle color
                        .shadow(radius: shadowRadius)
                        .zIndex(5)
                        .matchedGeometryEffect(id: "sphere1", in: namespace)
                    let medCircle = Circle()
                        .fill(Custom.coolBlue) // Circle color
                        .shadow(radius: shadowRadius)
                        .zIndex(6)
                        .matchedGeometryEffect(id: "sphere2", in: namespace)
                    let smallCircle = Circle()
                        .fill(Custom.medBlue) // Circle color
                        .shadow(radius: shadowRadius)
                        .zIndex(7)
                        .matchedGeometryEffect(id: "sphere3", in: namespace)
                    let image = Image("defaultImage")
                        .resizable()
                        .scaledToFit()
                        .zIndex(8)
                        .matchedGeometryEffect(id: "icon", in: namespace)
                    
                    
                    if moveStage == .top {
                        bgColor.ignoresSafeArea()
                            .opacity(0.0)
                            .matchedGeometryEffect(id: "bg", in: namespace)
                        
                        SphereView(sphereMoving: $sphereMoving, sphereIdx: 3, namespace: namespace,
                                   startX: midX, startY: bottomPos, endY: -height * 1,
                                   startSize: xsmall, endSize: large, shadowRadius: shadowRadius)
                        { largeCircle }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + moveSeparation * 3) {
                                    withAnimation {
                                        sphereMoving[3] = true
                                    }
                                }
                            }
                        SphereView(sphereMoving: $sphereMoving, sphereIdx: 2, namespace: namespace,
                                   startX: midX, startY: bottomPos, endY: -height * 1,
                                   startSize: xxsmall, endSize: med, shadowRadius: shadowRadius)
                        { medCircle }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + moveSeparation * 2) {
                                    withAnimation {
                                        sphereMoving[2] = true
                                    }
                                }
                            }
                        SphereView(sphereMoving: $sphereMoving, sphereIdx: 1, namespace: namespace,
                                   startX: midX, startY: bottomPos, endY: -height * 1,
                                   startSize: xxxsmall, endSize: small, shadowRadius: shadowRadius)
                        { smallCircle }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + moveSeparation) {
                                    withAnimation {
                                        sphereMoving[1] = true
                                    }
                                }
                            }
                        image
                            .position(x: midX, y: sphereMoving[0] ? -height * 1 : bottomPos)
                            .frame(width: sphereMoving[0] ? imgBig : imgSize,
                                   height: sphereMoving[0] ? imgBig : imgSize)
                            .onAppear {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        sphereMoving[0] = true
                                    }
                                }
                            }
                    } else if moveStage == .bottom {
                        bgColor.ignoresSafeArea()
                            .matchedGeometryEffect(id: "bg", in: namespace)
                        
                        largeCircle
                            .position(x: midX, y: bottomPos) // Center the circle
                            .frame(width: xsmall, height: xsmall)
                        medCircle
                            .position(x: midX, y: bottomPos) // Center the circle
                            .frame(width: xxsmall, height: xxsmall)
                        smallCircle
                            .position(x: midX, y: bottomPos) // Center the circle
                            .frame(width: xxxsmall, height: xxxsmall)
                        
                        image
                            .position(x: midX, y: bottomPos)
                            .frame(width: imgSize, height: imgSize)
                    } else if moveStage == .idle {
                        bgColor.ignoresSafeArea()
                            .matchedGeometryEffect(id: "bg", in: namespace)
                        
                        largeCircle
                            .position(x: midX, y: midY) // Center the circle
                            .frame(width: xsmall, height: xsmall)
                        medCircle
                            .position(x: midX, y: midY) // Center the circle
                            .frame(width: xxsmall, height: xxsmall)
                        smallCircle
                            .position(x: midX, y: midY) // Center the circle
                            .frame(width: xxxsmall, height: xxxsmall)
                        
                        image
                            .position(x: midX, y: midY)
                            .frame(width: imgSize, height: imgSize)
                    }
                }
            }
        }
        .zIndex(100)
        .onChange(of: moveStage) { newValue in
            if newValue != .top {
                sphereMoving = [false, false, false, false]
            }
        }
        .onTapGesture {
            if moveStage != .bottom {
                withAnimation {
                    moveStage = MoveStage.allCases[moveStage == MoveStage.allCases.last
                                                   ? 0
                                                   : moveStage.rawValue + 1]
                    if moveStage == .bottom {
                        DispatchQueue.main.asyncAfter(deadline: .now() + delayToTop) {
                            moveStage = .top
                        }
                    }
                }
            }
            print(moveStage)
        }
    }
}

struct SphereView<T: View>: View {
    @Binding var sphereMoving: [Bool]
    let sphereIdx: Int
    let namespace: Namespace.ID
    let startX: CGFloat
    var endX: CGFloat? = nil
    let startY: CGFloat
    var endY: CGFloat? = nil
    let startSize: CGFloat
    let endSize: CGFloat
    let shadowRadius: CGFloat
    var sphere: () -> T
    
    var body: some View {
        if sphereMoving[sphereIdx] {
            sphere()
                .position(x: endX ?? startX, y: endY ?? startY)
                .frame(width: endSize, height: endSize)
        } else {
            sphere()
                .position(x: startX, y: startY)
                .frame(width: startSize, height: startSize)
        }
    }
}
