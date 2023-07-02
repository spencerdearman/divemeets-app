//
//  ToolsMenu.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 6/1/23.
//

import SwiftUI

struct ToolsMenu: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                NavigationLink {
                    ListOptimizer()
                } label: {
                    Text("List Optimizer")
                        .font(.headline)
                        .bold()
                }
                Spacer()
                NavigationLink {
                    MeetScoreCalculator()
                } label: {
                    Text("Meet Score Predictor")
                        .font(.headline)
                        .bold()
                }
                Spacer()
            }
            .padding()
        }
    }
}


