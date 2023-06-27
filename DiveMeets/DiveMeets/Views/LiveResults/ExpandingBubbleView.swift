//
//  ExpandingBubbleView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 6/26/23.
//

import SwiftUI

struct HomeBubbleView: View{
    @Namespace var mainspace
    let gridItems = [GridItem(.adaptive(minimum: 300))]
    @Binding var diveTable: [[String]]
    @Binding var starSelected: Bool
    
    var body: some View {
        if starSelected{
            ZStack{
                Rectangle()
                    .foregroundColor(Custom.thinMaterialColor)
                    .mask(RoundedRectangle(cornerRadius: 40))
                    .frame(width: 200, height: 50)
                    .shadow(radius: 6)
                Text("Live Rankings")
                    .font(.title2).bold()
                    .matchedGeometryEffect(id: "ranking", in: mainspace)
            }
        } else {
            Text("Live Rankings")
                .font(.title2).bold()
                .padding(.top)
                .matchedGeometryEffect(id: "ranking", in: mainspace)
        }
        ZStack{
            ScrollView {
                LazyVGrid(columns: gridItems, spacing: 5) {
                    ForEach(diveTable, id: \.self) { elem in
                        HomeView(bubbleData: elem, starSelected: $starSelected)
                    }
                }
                .padding(20)
            }
        }
    }
}

struct HomeView: View {
    @State var hasScrolled = false
    @Namespace var namespace
    @State var show: Bool = false
    @State var bubbleData: [String]
    @Binding var starSelected: Bool
    
    init(bubbleData: [String], starSelected: Binding<Bool>) {
        self.bubbleData = bubbleData
        self._starSelected = starSelected
    }
    
    var body: some View{
        if show {
            OpenTileView(namespace: namespace, show: $show, bubbleData: $bubbleData)
                .onTapGesture {
                    starSelected = false
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        show.toggle()
                    }
                }
                .shadow(radius: 5)
        } else {
            ClosedTileView(namespace: namespace, show: $show, bubbleData: $bubbleData)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        starSelected = true
                        show.toggle()
                    }
                }
        }
    }
}

struct ClosedTileView: View {
    @Environment(\.colorScheme) var currentMode
    var namespace: Namespace.ID
    @Binding var show: Bool
    @Binding var bubbleData: [String]
    
    private var bgColor: Color {
        currentMode == .light ? Custom.tileColor : Custom.tileColor
    }
    
    //[Place: (Left to dive, order, last round place, last round score, current place,
    //current score, name, last dive average, event average score, avg round score
    
    var body: some View{
        VStack{
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(.white)
        .background(
            bgColor.matchedGeometryEffect(id: "background", in: namespace)
        )
        .mask(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .matchedGeometryEffect(id: "mask", in: namespace)
        )
        .shadow(radius: 5)
        .overlay(
            ZStack {
                VStack(alignment: .leading, spacing: 12){
                    HStack {
                        Text(bubbleData[6])
                            .font(.largeTitle)
                            .matchedGeometryEffect(id: "name", in: namespace)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if Bool(bubbleData[0])! {
                            Image(systemName: "checkmark")
                                .offset(x: -60)
                                .matchedGeometryEffect(id: "checkmark", in: namespace)
                        }
                        Text("Current Place: " + bubbleData[4])
                            .font(.title2).scaledToFit()
                            .matchedGeometryEffect(id: "currentPlace", in: namespace)
                    }
                    
                    HStack {
                        Text("Current Score: " + bubbleData[5])
                            .font(.footnote.weight(.semibold))
                        .matchedGeometryEffect(id: "currentScore", in: namespace)
                        Spacer()
                        Text("Last Round Place: " + bubbleData[2])
                            .font(.footnote.weight(.semibold)).scaledToFit()
                            .matchedGeometryEffect(id: "previous", in: namespace)
                    }
                }
                .padding(20)
            }
        )
        .frame(height: 120)
        .padding(1)
    }
}

struct OpenTileView: View {
    @Environment(\.colorScheme) var currentMode
    var namespace: Namespace.ID
    @Binding var show: Bool
    @Binding var bubbleData: [String]
    
    private var bgColor: Color {
        currentMode == .light ? Custom.tileColor : Custom.tileColor
    }
    
    private var txtColor: Color {
        currentMode == .light ? .black : .white
    }
    
    //[Place: (Left to dive, order, last round place, last round score, current place,
    //current score, name, last dive average, event average score, avg round score
    
    var body: some View{
        
        VStack{
            Spacer()
            VStack(alignment: .leading, spacing: 12){
                HStack {
                    VStack(alignment: .leading){
                        Text(bubbleData[6])
                            .font(.largeTitle)
                            .foregroundColor(txtColor)
                            .scaledToFit()
                            .matchedGeometryEffect(id: "name", in: namespace)
                        //.frame(maxWidth: .infinity, alignment: .leading)
                        //.padding(10)
                        HStack {
                            Text("Current Place: " + bubbleData[4])
                                .scaledToFit()
                                .fontWeight(.semibold)
                                .matchedGeometryEffect(id: "currentPlace", in: namespace)
                            if Bool(bubbleData[0])! {
                                Image(systemName: "checkmark")
                                    .matchedGeometryEffect(id: "checkmark", in: namespace)
                            }
                        }
                        .foregroundColor(txtColor)
                            Text("Current Score: " + bubbleData[5])
                                .font(.footnote.weight(.semibold)).scaledToFit()
                                .foregroundColor(txtColor)
                                .matchedGeometryEffect(id: "currentScore", in: namespace)
                    }
                    MiniProfileImage(diverID: String(bubbleData[7].utf16.dropFirst(67)) ?? "", width: 150, height: 200)
                        .scaledToFit()
                        .padding(.horizontal)
                        .shadow(radius: 10)
                }
                ZStack{
                    Rectangle()
                        .foregroundColor(Custom.thinMaterialColor)
                        .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .matchedGeometryEffect(id: "blur", in: namespace)
                        .shadow(radius: 10)
                    VStack(spacing: 10){
                        Text("Advanced Statistics")
                            .font(.title2)
                            .fontWeight(.bold).underline()
                        HStack{
                            Text("Order: " + bubbleData[1])
                            Text("Last Round Place: " + bubbleData[2])
                                .matchedGeometryEffect(id: "previous", in: namespace)
                        }
                        .fontWeight(.semibold)
                        Text("Last Round Score: " + bubbleData[3])
                            .fontWeight(.semibold)
                        Text("Last Dive Average: " + bubbleData[8])
                            .fontWeight(.semibold)
                        Text("Average Event Score: " + bubbleData[9])
                            .fontWeight(.semibold)
                        Text("Average Round Score: " + bubbleData[10])
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(txtColor)
                    
                }
                Spacer()
            }
            .padding(20)
        }
        .foregroundStyle(.black)
        .background(
            bgColor.matchedGeometryEffect(id: "background", in: namespace)
        )
        .mask(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .matchedGeometryEffect(id: "mask", in: namespace)
        )
        .frame(height: 500)
    }
}
