//
//  LiveResultsView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/8/23.
//
//Loading balls https://github.com/SwiftfulThinking/SwiftfulLoadingIndicators/blob/main/Sources/SwiftfulLoadingIndicators/Animations/LoadingThreeBallsTriangle.swift


import SwiftUI
import Combine
import SwiftSoup

struct LiveResultsView: View {
    var request: String =
    "https://secure.meetcontrol.com/divemeets/system/livestats.php?event=stats-9037-3470-9-Started"
    @State var html: String = ""
    @State var rows: [[String: String]] = []
    @State var columns: [String] = []
    @State var focusViewList: [String: Bool] = [:]
    @State private var moveRightLeft = false
    @State private var offset: CGFloat = 0
    @State private var currentViewIndex = 0
    @State private var roundString = ""
    @State private var title: String = ""
    @State private var starSelected: Bool = false
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    @State var lastDiverInformation:
    //  name, link, last round place, last round total, order, place, total, dive, height, dd, score total, [judges scores]
    (String, String, Int, Double, Int, Int, Double, String, String, Double, Double, String) =
    ("", "", 0, 0.0, 0, 0, 0.0, "", "", 0.0, 0.0, "")
    @State var nextDiverInformation: (String, String, Int, Double, Int, String, String, Double, Double, Double, Double) = ("", "", 0, 0.0, 0, "", "", 0.0, 0.0, 0.0, 0.0)
    //[Place: (Left to dive, order, last round place, last round score, current place,
    //current score, name, last dive average, event average score, avg round score
    @State var diveTable: [[String]] = []
    
    let screenFrame = Color(.systemBackground)
    
    var body: some View {
        ZStack {
            LRWebView(request: request, html: $html)
                .onChange(of: html) { newValue in
                    
                    do {
                        let document: Document = try SwiftSoup.parse(newValue)
                        guard let body = document.body() else {
                            return
                        }
                        let table = try body.getElementById("Results")
                        let rows = try table?.getElementsByTag("tr")
                        let upperTables = try rows![1].getElementsByTag("tbody")
                        let individualTables = try upperTables[0].getElementsByTag("table")
                        
                        let linkHead = "https://secure.meetcontrol.com/divemeets/system/"
                        
                        //Title
                        title = try rows![0].getElementsByTag("td")[0].text().replacingOccurrences(of: "Unofficial Statistics ", with: "")
                        
                        //Last Diver
                        
                        var lastDiverName = ""
                        var lastDiverProfileLink = ""
                        var lastRoundPlace = 0
                        var lastRoundTotalScore = 0.0
                        var order = 0
                        var currentPlace = 0
                        var currentTotal = 0.0
                        var currentDive = ""
                        var height = ""
                        var dd = 0.0
                        var score = 0.0
                        var judgesScores = ""
                        
                        let lastDiverStr = try individualTables[0].text()
                        let lastDiver = try individualTables[0].getElementsByTag("a")
                        lastDiverName = try lastDiver[0].text()
                        var tempLink = try individualTables[0].getElementsByTag("a").attr("href")
                        lastDiverProfileLink = linkHead + tempLink
                        
                        lastRoundPlace = Int(lastDiverStr.slice(from: "Last Round Place: ", to: " Last Round") ?? "")!
                        lastRoundTotalScore = Double(lastDiverStr.slice(from: "Last Round Total Score: ", to: " Diver O") ?? "")!
                        order = Int(lastDiverStr.slice(from: "Diver Order: ", to: " Current") ?? "")!
                        currentPlace = Int(lastDiverStr.slice(from: "Current Place: ", to: " Current") ?? "")!
                        currentTotal = Double(lastDiverStr.slice(from: "Current Total Score: ", to: " Current") ?? "")!
                        currentDive = lastDiverStr.slice(from: "Current Dive:   ", to: " Height") ?? ""
                        height = lastDiverStr.slice(from: "Height: ", to: " DD:") ?? ""
                        dd = Double(lastDiverStr.slice(from: "DD: ", to: " Score") ?? "")!
                        score = Double(lastDiverStr.slice(from: String(dd) + " Score: ", to: " Judges") ?? "")!
                        judgesScores = String(lastDiverStr.suffix(11))
                        lastDiverInformation = (lastDiverName, lastDiverProfileLink, lastRoundPlace, lastRoundTotalScore, order, currentPlace, currentTotal, currentDive, height, dd, score, judgesScores)
                        
                        //Upcoming Diver
                        
                        var nextDiverName = ""
                        var nextDiverProfileLink = ""
                        var nextDive = ""
                        var avgScore = 0.0
                        var maxScore = 0.0
                        var forFirstPlace = 0.0
                        
                        let upcomingDiverStr = try individualTables[2].text()
                        let nextDiver = try individualTables[2].getElementsByTag("a")
                        nextDiverName = try nextDiver[0].text()
                        tempLink = try individualTables[2].getElementsByTag("a").attr("href")
                        nextDiverProfileLink = linkHead + tempLink
                        
                        lastRoundPlace = Int(upcomingDiverStr.slice(from: "Last Round Place: ", to: " Last Round") ?? "")!
                        lastRoundTotalScore = Double(upcomingDiverStr.slice(from: "Last Round Total Score: ", to: " Diver O") ?? "")!
                        order = Int(upcomingDiverStr.slice(from: "Order: ", to: " Next Dive") ?? "")!
                        nextDive = upcomingDiverStr.slice(from: "Next Dive:   ", to: " Height") ?? ""
                        height = upcomingDiverStr.slice(from: "Height: ", to: " DD:") ?? ""
                        dd = Double(upcomingDiverStr.slice(from: "DD: ", to: " History for") ?? "")!
                        avgScore = Double(upcomingDiverStr.slice(from: "Avg Score: ", to: "  Max Score") ?? "")!
                        maxScore = Double(upcomingDiverStr.slice(from: "Max Score Ever: ", to: " Needed") ?? "")!
                        var result = ""
                        for char in upcomingDiverStr.reversed() {
                            if char == " " {
                                break
                            }
                            result = String(char) + result
                        }
                        forFirstPlace = Double(result)!
                        nextDiverInformation = (nextDiverName, nextDiverProfileLink, lastRoundPlace, lastRoundTotalScore, order, nextDive, height, dd, avgScore, maxScore, forFirstPlace)
                        
                        //Current Round
                        let currentRound = try rows![8].getElementsByTag("td")
                        roundString = try currentRound[0].text()
                        
                        //Diving Table
                        
                        for (i, t) in rows!.enumerated(){
                            if i < rows!.count - 1 && i >= 10{
                                var tempList: [String] = []
                                for (i, v) in try t.getElementsByTag("td").enumerated() {
                                    if i > 9 { break }
                                    if i == 0 {
                                        if try v.text() == "" {
                                            tempList.append("true")
                                        } else {
                                            tempList.append("false")
                                        }
                                    } else if i == 6 {
                                        focusViewList[try v.text()] = false
                                        tempList.append(try v.text())
                                        let halfLink = try v.getElementsByTag("a").attr("href")
                                        tempList.append(linkHead + halfLink)
                                    } else {
                                        tempList.append(try v.text())
                                    }
                                }
                                diveTable.append(tempList)
                            }
                        }
                        //print(diveTable)
                        
                    } catch  {
                        print("Parsing finished live event failed")
                    }
                }
            
            Color.white.ignoresSafeArea()
            NavigationView{
                VStack{
                    //LiveBarAnimation()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    if !starSelected {
                        VStack{
                            Text(title)
                                .font(.title2).bold()
                            Text(roundString)
                            SwipingView(lastInfo: $lastDiverInformation, nextInfo: $nextDiverInformation)
                                .frame(height: 350)
                            Text("Live Rankings")
                                .font(.title2).bold()
                                .offset(y: -15)
                        }
                    }
                    ScalingScrollView(records: diveTable) { (elem) in
                        ResultsBubbleView(elements: elem, focusViewList: $focusViewList)
                    }
                    .onChange(of: focusViewList, perform: {[focusViewList] newValue in
                        if focusViewList.count == newValue.count{
                            starSelected.toggle()
                        }
                    })
                    .padding(.bottom, maxHeightOffset)
                    .padding(.top)
                    .animation(.easeOut(duration: 1), value: starSelected)
                }
                .offset(y: -50)
            }
        }
    }
}

struct LiveBarAnimation: View {
    @State private var moveRightLeft = false
    var body: some View {
        VStack{
            ZStack{
                Capsule() // inactive
                    .frame(width: 128, height: 6, alignment: .center)
                    .foregroundColor(Color(.systemGray4))
                Capsule()
                    .clipShape(Rectangle().offset(x: moveRightLeft ? 80: -80))
                    .frame(width: 100, height: 6, alignment: .leading)
                    .foregroundColor(Color(.systemMint))
                    .offset(x: moveRightLeft ? 14 : -14)
                    .animation(Animation.easeInOut(duration: 0.5).delay(0.2).repeatForever(autoreverses: true))
                    .onAppear{
                        moveRightLeft.toggle()
                    }
            }
            Text("Live Results")
        }
    }
}

struct LastDiverView: View
{
    @Binding var lastInfo:
    //  name, link, last round place, last round total, order, place, total, dive, height, dd, score total, [judges scores]
    (String, String, Int, Double, Int, Int, Double, String, String, Double, Double, String)
    var body: some View {
        VStack{
            Group{
                HStack{
                    VStack(alignment: .leading){
                        Text(lastInfo.0)
                            .font(.title3).bold()
                        Text("Last Round Place: " + String(lastInfo.2))
                        Text("Last Round Total: " + String(lastInfo.3))
                        HStack{
                            Text("Order: " + String(lastInfo.4))
                            Text("Place: " + String(lastInfo.5))
                        }
                        Text("Current Total: " + String(lastInfo.6))
                            .font(.headline)
                    }
                    .padding()
                    MiniProfileImage(diverID: String(lastInfo.1.utf16.dropFirst(67)) ?? "")
                        .scaledToFit()
                        .padding(.horizontal)
                }
                Text(lastInfo.7)
                    .font(.title3).bold()
                HStack{
                    Text("Height: " + lastInfo.8)
                    Text("DD: " + String(lastInfo.9))
                    Text("Score Total: " + String(lastInfo.10))
                }
            }
            Group{
                Text("Judges Scores")
                    .underline()
                Text(lastInfo.11)
                    .font(.headline)
            }
        }
    }
}

struct NextDiverView: View
{
    //nextDiverInformation = (nextDiverName, nextDiverProfileLink, lastRoundPlace, lastRoundTotalScore, order, nextDive, height, dd, avgScore, maxScore, forFirstPlace)
    @Binding var nextInfo: (String, String, Int, Double, Int, String, String, Double, Double, Double, Double)
    var body: some View {
        VStack{
            Group{
                HStack{
                    VStack(alignment: .leading){
                        Text(nextInfo.0)
                            .font(.title3).bold()
                        Text("Last Round Place: " + String(nextInfo.2))
                        Text("Last Round Total: " + String(nextInfo.3))
                        HStack{
                            Text("Order: " + String(nextInfo.4))
                        }
                    }
                    .padding()
                    MiniProfileImage(diverID: String(nextInfo.1.utf16.dropFirst(67)) ?? "")
                        .scaledToFit()
                        .padding(.horizontal)
                }
            }
            Group{
                VStack{
                    Text(nextInfo.5)
                        .font(.title3)
                        .bold()
                    HStack{
                        Text("Height: " + nextInfo.6)
                        Text("DD: " + String(nextInfo.7))
                    }
                    HStack{
                        Text("Average Score: " + String(nextInfo.8))
                        Text("Max Score: " + String(nextInfo.9))
                    }
                    Text("For First Place: " + String(nextInfo.10))
                }
                .padding(.bottom)
            }
        }
    }
}

struct SwipingView: View
{
    @Binding var lastInfo:
    (String, String, Int, Double, Int, Int, Double, String, String, Double, Double, String)
    @Binding var nextInfo:
    (String, String, Int, Double, Int, String, String, Double, Double, Double, Double)
    var body: some View {
        TabView {
            LastDiverView(lastInfo: $lastInfo)
                .frame(width: 400, height: 250)
                .background(Color(.systemGray4).opacity(0.95))
                .cornerRadius(40)
                .shadow(color: Color.black.opacity(0.7), radius: 5, x: 0, y: 2)
                .padding()
                .tabItem {
                    Text("Last Diver")
                }
            
            NextDiverView(nextInfo: $nextInfo)
                .frame(width: 400, height: 250)
                .background(Color(.systemGray4).opacity(0.95))
                .cornerRadius(40)
                .shadow(color: Color.black.opacity(0.7), radius: 5, x: 0, y: 2)
                .padding()
                .tabItem {
                    Text("Next Diver")
                }
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
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
        ZStack {
            Rectangle()
                .foregroundColor(bubbleColor)
            VStack {
                VStack(alignment: .leading) {
                    HStack(alignment: .lastTextBaseline) {
                        if Bool(elements[0])!{
                            Image(systemName: "checkmark.circle")
                        }
                        let link = elements[7]
                        NavigationLink {
                            ProfileView(
                                link: link,
                                diverID: String(link.utf16.dropFirst(67)) ?? "")
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
                        Text("Last Round Place: " + elements[2])
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

struct testView: View {
    var body: some View {
        Rectangle()
        Text("This is the Testing View")
    }
}
