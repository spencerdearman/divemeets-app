//
//  ExpandingBubbleView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 6/26/23.
//

import SwiftUI

struct HomeBubbleView: View{
    let gridItems = [GridItem(.adaptive(minimum: 300))]
    @Binding var diveTable: [[String]]
    @Binding var starSelected: Bool
    
    var body: some View {
        Text("Live Rankings")
            .font(.title2).bold()
            .padding(.top)
        ZStack{
            //Custom.darkBlue
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
    var namespace: Namespace.ID
    @Binding var show: Bool
    @Binding var bubbleData: [String]
    
    //[Place: (Left to dive, order, last round place, last round score, current place,
    //current score, name, last dive average, event average score, avg round score
    
    var body: some View{
        VStack{
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(.white)
        .background(
            Color.white.matchedGeometryEffect(id: "background", in: namespace)
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
                        Text("Current Place: " + bubbleData[4])
                            .font(.title2).scaledToFit()
                            .matchedGeometryEffect(id: "currentPlace", in: namespace)
                    }
                    Text("Current Score: " + bubbleData[5])
                        .font(.footnote.weight(.semibold))
                        .matchedGeometryEffect(id: "currentScore", in: namespace)
                    }
                    .padding(20)
            }
        )
        .frame(height: 130)
        .padding(1)
    }
}

struct OpenTileView: View {
    var namespace: Namespace.ID
    @Binding var show: Bool
    @Binding var bubbleData: [String]
    
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
                            }
                        }
                        Text("Current Score: " + bubbleData[5])
                            .font(.footnote.weight(.semibold)).scaledToFit()
                            .matchedGeometryEffect(id: "currentScore", in: namespace)
                    }
                    MiniProfileImage(diverID: String(bubbleData[7].utf16.dropFirst(67)) ?? "", width: 150, height: 200)
                        .scaledToFit()
                        .padding(.horizontal)
                        .shadow(radius: 10)
                }
                ZStack{
                    Rectangle()
                        .fill(.ultraThinMaterial)
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
                    
                }
                Spacer()
            }
            .padding(20)
        }
        .foregroundStyle(.black)
        .background(
            Color.white.matchedGeometryEffect(id: "background", in: namespace)
        )
        .mask(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .matchedGeometryEffect(id: "mask", in: namespace)
        )
        .frame(height: 500)
    }
}
