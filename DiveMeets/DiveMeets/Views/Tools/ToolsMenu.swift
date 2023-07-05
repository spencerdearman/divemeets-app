//
//  ToolsMenu.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 6/1/23.
//

import SwiftUI

struct ToolsMenu: View {
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 57
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Tools")
                    .font(.title)
                    .bold()
                Spacer()
                
                NavigationLink(destination: MeetScoreCalculator()) {
                    ZStack {
                        Circle()
                            .fill(Custom.coolBlue)
                            .shadow(radius: 15)
                            .padding()
                        
                        Text("Meet Score Calculator")
                            .foregroundColor(.primary)
                            .font(.title2)
                            .bold()
                            .padding()
                    }
                }
                .contentShape(Circle())
                
                Spacer()
                
                NavigationLink(destination: JudgeScoreCalculator()) {
                    ZStack {
                        Circle()
                            .fill(Custom.coolBlue)
                            .shadow(radius: 15)
                            .padding()
                        
                        Text("Judge Score Calculator")
                            .foregroundColor(.primary)
                            .font(.title2)
                            .bold()
                            .padding()
                    }
                }
                .contentShape(Circle())
                
                Spacer()
            }
            .padding(.bottom, maxHeightOffset)
        }
    }
}


