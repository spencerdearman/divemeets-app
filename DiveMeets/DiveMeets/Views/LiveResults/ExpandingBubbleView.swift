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
                OpenTileView(namespace: namespace, show: $show)
                    .onTapGesture {
                        starSelected = false
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            show.toggle()
                        }
                    }
                    .shadow(radius: 5)
            } else {
                ClosedTileView(namespace: namespace, show: $show)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            starSelected = true
                            show.toggle()
                        }
                    }
                    .shadow(radius: 5)
            }
    }
}

struct ClosedTileView: View {
    var namespace: Namespace.ID
    @Binding var show: Bool
    
    var body: some View{
        VStack{
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(.white)
        .background(
            Custom.coolBlue.matchedGeometryEffect(id: "background", in: namespace)
        )
        .mask(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .matchedGeometryEffect(id: "mask", in: namespace)
        )
        .overlay(
            VStack(alignment: .leading, spacing: 12){
                Text("Swiftui")
                    .font(.largeTitle)
                    .matchedGeometryEffect(id: "title", in: namespace)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("20 sections - 3 hours")
                    .font(.footnote.weight(.semibold))
                    .matchedGeometryEffect(id: "footnote", in: namespace)
                Text("More subtext")
                    .font(.footnote)
                    .matchedGeometryEffect(id: "text", in: namespace)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
                .padding(20)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .matchedGeometryEffect(id: "blur", in: namespace)
                )
                .offset(y: 20)
                .padding(20)
        )
        .frame(height: 200)
        //.padding(20)
    }
}

struct OpenTileView: View {
    var namespace: Namespace.ID
    @Binding var show: Bool
    
    var body: some View{
        
        VStack{
            Spacer()
            VStack(alignment: .leading, spacing: 12){
                Text("20 sections - 3 hours")
                    .font(.footnote.weight(.semibold))
                    .matchedGeometryEffect(id: "footnote", in: namespace)
                Text("Swiftui")
                    .font(.largeTitle)
                    .matchedGeometryEffect(id: "title", in: namespace)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("More subtext")
                    .font(.footnote)
                    .matchedGeometryEffect(id: "text", in: namespace)
            }
            .padding(20)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .blur(radius: 30)
                    .matchedGeometryEffect(id: "blur", in: namespace)
            )
        }
        .foregroundStyle(.black)
        .background(
            Custom.lightBlue.matchedGeometryEffect(id: "background", in: namespace)
        )
        .mask(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .matchedGeometryEffect(id: "mask", in: namespace)
        )
        .frame(height: 500)
    }
}



struct ResultsBubbleView: View {
    @Environment(\.colorScheme) var currentMode
    @Binding private var focusViewList: [String: Bool]
    @State private var focusBool: Bool = false
    
    private var bubbleColor: Color {
        currentMode == .light ? .white : .black
    }
    private var elements: [String]
    
    init(elements: [String], focusViewList: Binding<[String: Bool]>) {
        self.elements = elements
        self._focusViewList = focusViewList
    }
    
    //[Place: (Left to dive, order, last round place, last round score, current place,
    //current score, name, last dive average, event average score, avg round score
    var body: some View {
        if focusViewList[elements[6]] ?? false {
            Rectangle()
                .foregroundColor(.blue)
        } else {
            ZStack {
                Rectangle()
                    .foregroundColor(bubbleColor)
                VStack {
                    VStack(alignment: .leading) {
                        HStack(alignment: .lastTextBaseline) {
                            if Bool(elements[0]) ?? false {
                                Image(systemName: "checkmark.circle")
                            }
                            let link = elements[7]
                            NavigationLink {
                                ProfileView(profileLink: link)
                            } label: {
                                Text(elements[6])
                                    .font(.title3)
                                    .bold()
                                    .scaledToFit()
                                    .minimumScaleFactor(0.5)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(1)
                            }
                            Text(elements[5])
                                .font(.title3).foregroundColor(.red)
                            Spacer()
                        }
                        HStack{
                            Button {
                                focusBool.toggle()
                                focusViewList[elements[6]] = focusBool
                            } label: {
                                if focusBool {
                                    Image(systemName: "star.fill")
                                } else {
                                    Image(systemName: "star")
                                }
                            }
                            Text("Diving Order: " + elements[1])
                            Text("Last Round Place: " + (elements[2] == "0" ? "N/A" : elements[2]))
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                focusBool = focusViewList[elements[6]] ?? false
            }
            .onTapGesture {
                print(elements[3])
            }
        }
    }
}
