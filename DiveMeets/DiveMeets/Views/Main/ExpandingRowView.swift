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
    
    var body: some View {
        GeometryReader { g in
            NavigationView {
                ZStack {
                    Color.gray.ignoresSafeArea()
                    
                    if !show {
        //                VStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .foregroundColor(.white)
                                .matchedGeometryEffect(id: "rect", in: namespace)
    //                            .frame(height: 0)
                                .frame(height: 0)
                                .padding()
    //                        AnyView(
                            HStack {
                                    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
    //                    )
                                
                                .background(.white)
                                .cornerRadius(30)
                                .matchedGeometryEffect(id: "row", in: namespace)
                                .frame(height: 100)
                                .padding()
    //                        .background(RoundedRectangle(cornerRadius: 30)
    //                            .foregroundColor(.white)
    //                            .matchedGeometryEffect(id: "rect", in: namespace)
    //                            .frame(height: 0))
                            
                        }
                        .onTapGesture {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                                show.toggle()
                            }
                        }
                        
    //                    .background(Color.gray.matchedGeometryEffect(id: "bg", in: namespace))
        //                }
        //                .padding([.leading, .trailing])
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                            //                            .padding([.top, .bottom])
                                .foregroundColor(.white)
                            //                            .background(Color.white.matchedGeometryEffect(id: "bg", in: namespace))
                            //                            .cornerRadius(30)
                                .matchedGeometryEffect(id: "rect", in: namespace)
                                .frame(height: g.size.height + 50)
                            ZStack(alignment: .topLeading) {
                                
    //                            AnyView(
    //                            HStack {
    //                                Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    //                                Spacer()
    //                                Image(systemName: "chevron.right")
    //                            }
                                ProfileView(profileLink: "https://secure.meetcontrol.com/divemeets/system/profile.php?number=56961")
    //                            )
//                                .padding(.top, 30)
    //                            .background(.white)
    //                            .cornerRadius(30)
                                .matchedGeometryEffect(id: "row", in: namespace)
//                                .frame(height: g.size.height)
                                Button(action: {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                                        show.toggle()
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 22))
                                }
                                .padding()
                                
//                                Spacer()
                            }
    //                        .background(RoundedRectangle(cornerRadius: 30)
    //                                    //                            .padding([.top, .bottom])
    //                            .foregroundColor(.white)
    //                                    //                            .background(Color.white.matchedGeometryEffect(id: "bg", in: namespace))
    //                                    //                            .cornerRadius(30)
    //                            .matchedGeometryEffect(id: "rect", in: namespace)
    //                            .frame(height: g.size.height))
                            
        //                    Spacer()
                        }
                        
        //                .padding([.leading, .trailing])
                    }
                }
            }
            
        }
//        .ignoresSafeArea()
    }
}

struct ExpandingRowView_Previews: PreviewProvider {
    static var previews: some View {
        ExpandingRowView()
    }
}
