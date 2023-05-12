//
//  ScalingScrollView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 5/11/23.
//

import SwiftUI

struct ScalingScrollView<T: RandomAccessCollection, U: View>: View where T.Element: Hashable {
    @Environment(\.colorScheme) var currentMode
    @ScaledMetric private var frameHeight: CGFloat = 100
    
    private let grayValue: CGFloat = 0.95
    private let grayValueDark: CGFloat = 0.10
    
    private var grayColor: Color {
        currentMode == .light
        ? Color(red: grayValue, green: grayValue, blue: grayValue)
        : Color(red: grayValueDark, green: grayValueDark, blue: grayValueDark)
    }
    
    var records: T
    var bgColor: Color = Color(red: 0.95, green: 0.95, blue: 0.95)
    var viewGenerator: (T.Element) -> U
    
    var body: some View {
        GeometryReader { mainView in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ForEach(records, id: \.self) { record in
                        GeometryReader { item in
                            viewGenerator(record)
                                .cornerRadius(15)
                                .scaleEffect(scaleValue(mainFrame: mainView.frame(in: .global).minY,
                                                        minY: item.frame(in: .global).minY),
                                             anchor: .bottom)
                                .opacity(scaleValue(mainFrame: mainView.frame(in: .global).minY,
                                                    minY: item.frame(in: .global).minY))
                        }
                        .frame(height: frameHeight)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 25)
            }
            .zIndex(1)
        }
                .background(bgColor)
    }
    
    func scaleValue(mainFrame: CGFloat, minY: CGFloat) -> CGFloat {
        withAnimation(.easeOut) {
            let scale = (minY - 25) / mainFrame
            
            if scale > 1 {
                return 1
            } else if scale == 0 {
                return 1e-5
            } else {
                return scale
            }
        }
    }
}