//
//  ToolsMenu.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 6/1/23.
//

import SwiftUI

struct ToolsMenu: View {
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 57
    
    private var screenWidth = UIScreen.main.bounds.width
    private var screenHeight = UIScreen.main.bounds.height
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Custom.background.ignoresSafeArea()
                VStack {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Custom.thinMaterialColor)
                            .mask(RoundedRectangle(cornerRadius: 40))
                            .frame(width: 120, height: 40)
                            .shadow(radius: 6)
                        Text("Tools")
                            .font(.title2).bold()
                    }
                    Spacer()
                    JudgeScoreCalculator()
                    Spacer()
                    NavigationLink(destination: MeetScoreCalculator()) {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Custom.thinMaterialColor)
                                .mask(RoundedRectangle(cornerRadius: 30))
                                .frame(width: screenWidth * 0.8, height: screenHeight * 0.15)
                                .shadow(radius: 10)
                            
                            Text("Meet Score Calculator")
                                .foregroundColor(.primary)
                                .font(.title2)
                                .bold()
                                .padding()
                        }
                    }
                    .contentShape(Rectangle())
                    Spacer()
                }
                .padding(.bottom, maxHeightOffset)
            }
        }
    }
}


