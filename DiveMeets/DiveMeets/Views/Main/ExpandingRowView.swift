//
//  ExpandingRowView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 6/24/23.
//

import SwiftUI

struct ExpandingRowView: View {
    @Namespace var namespace
    @State var show = false
    @State var pressed = false
    @State var list = ["Hello", "My", "Name", "Is", "Logan"]
    
    var body: some View {
        GeometryReader { g in
            NavigationView {
                ForEach(list, id: \.self) { elem in
                    ZStack {
                        Color.gray.ignoresSafeArea()
                        
                        if !show {
                            ZStack {
                                RoundedRectangle(cornerRadius: 30)
                                    .foregroundColor(.white)
                                    .matchedGeometryEffect(id: "rect", in: namespace)
                                    .frame(height: 0)
                                    .padding()
                                HStack {
                                    Text(elem)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .background(.white)
                                .cornerRadius(30)
                                .matchedGeometryEffect(id: "row", in: namespace)
                                .frame(height: 100)
                                .padding()
                            }
                            .onTapGesture {
                                Task {
                                    await animate(duration: 2, animation: .spring(response: 2,
                                                                                  dampingFraction: 0.9)) {
                                        show.toggle()
                                    }
                                    pressed = true
                                }
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 30)
                                    .foregroundColor(.white)
                                    .matchedGeometryEffect(id: "rect", in: namespace)
                                    .frame(height: g.size.height + 50)
                                if pressed {
                                    let link = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=56961"
                                    ZStack(alignment: .topLeading) {
                                        ProfileView(profileLink: link)
                                        .matchedGeometryEffect(id: "row", in: namespace)
                                        Button(action: {
                                            withAnimation(.spring(response: 0.6,
                                                                  dampingFraction: 0.9)) {
                                                show.toggle()
                                                pressed = false
                                            }
                                        }) {
                                            Image(systemName: "chevron.left")
                                                .font(.system(size: 22))
                                        }
                                        .padding()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        //        .ignoresSafeArea()
    }
}
