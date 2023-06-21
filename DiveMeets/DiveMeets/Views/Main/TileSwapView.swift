//
//  TileSwapView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 6/20/23.
//

import SwiftUI

struct TileSwapView: View {
    private let width: CGFloat = 300
    private let height: CGFloat = 200
    private let offset: CGFloat = 20
    private let cornerRadius: CGFloat = 15
    private let shadowRadius: CGFloat = 20
    private let swapTime: CGFloat = 0.2
    @State private var zIndices: [Double] = [1, 0]
    @State private var isInTransition: [Bool] = [false, false]
    
    private func getYOffset(index: Int) -> CGFloat {
        if isInTransition[index] {
            return -height + offset
        } else if zIndices[index] == 1 {
            return 0.0
        } else {
            return offset
        }
    }
    
    private func onTap(index: Int) {
        isInTransition[index] = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + swapTime) {
            zIndices.reverse()
            isInTransition[index] = false
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.red)
                .frame(width: zIndices[0] == 1 ? width : width * 0.9, height: height)
                .shadow(radius: shadowRadius)
                .cornerRadius(cornerRadius)
                .zIndex(zIndices[0])
                .onTapGesture {
                    onTap(index: 0)
                }
                .offset(y: getYOffset(index: 0))
                .animation(.spring(), value: isInTransition[0])
                .animation(.spring(), value: zIndices)
            Rectangle()
                .fill(.blue)
                .frame(width: zIndices[1] == 1 ? width : width * 0.9, height: height)
                .shadow(radius: shadowRadius)
                .cornerRadius(cornerRadius)
                .zIndex(zIndices[1])
                .onTapGesture {
                    onTap(index: 1)
                }
                .offset(y: getYOffset(index: 1))
                .animation(.spring(), value: isInTransition[1])
                .animation(.spring(), value: zIndices)
                
        }
    }
}

struct TileSwapView_Previews: PreviewProvider {
    static var previews: some View {
        TileSwapView()
    }
}
