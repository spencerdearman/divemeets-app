//
//  TileSwapView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 6/20/23.
//

import SwiftUI

struct TileSwapView: View {
    private let width: CGFloat = 100
    private let height: CGFloat = 80
    @State private var zIndices: [Double] = [1, 0]
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.red)
                .frame(width: width, height: height)
                .zIndex(zIndices[0])
                .onTapGesture {
                    zIndices.reverse()
                }
            Rectangle()
                .fill(.blue)
                .frame(width: width, height: height)
                .offset(y: 20)
                .zIndex(zIndices[1])
                .onTapGesture {
                    zIndices.reverse()
                }
        }
    }
}

struct TileSwapView_Previews: PreviewProvider {
    static var previews: some View {
        TileSwapView()
    }
}
