//
//  LiveResultsView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/8/23.
//
//


import SwiftUI
import SwiftSoup

//  name, link, last round place, last round total, order, place, total, dive, height, dd,
//score total, [judges scores]
typealias LastDiverInfo = (String, String, Int, Double, Int, Int, Double, String, String, Double, Double, String)

//nextDiverName, nextDiverProfileLink, lastRoundPlace, lastRoundTotalScore, order, nextDive,
//height, dd, avgScore, maxScore, forFirstPlace
typealias NextDiverInfo = (String, String, Int, Double, Int, String, String, Double, Double, Double, Double)

//                    [[Left to dive, order, last round place, last round score, current place,
//                      current score, name, link, last dive average, event average score, avg round score]]
typealias DiveTable = [[String]]

struct LiveResultsView: View {
    var request: String
    @State var shiftingBool: Bool = false
    let screenFrame = Color(.systemBackground)
    
    var body: some View {
        ZStack {
            parseBody(request: request, shiftingBool: $shiftingBool)
        }
    }
}

struct parseBody: View {
    var request: String
    @State var html: String = ""
    @State var rows: [[String: String]] = []
    @State var columns: [String] = []
    @State var focusViewList: [String: Bool] = [:]
    @State private var moveRightLeft = false
    @State private var offset: CGFloat = 0
    @State private var currentViewIndex = 0
    @State private var roundString = ""
    @State private var title: String = ""
    @State var starSelected: Bool = false
    @Binding var shiftingBool: Bool
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    @State var lastDiverInformation: LastDiverInfo = ("", "", 0, 0.0, 0, 0, 0.0, "", "", 0.0, 0.0, "")
    @State var nextDiverInformation: NextDiverInfo = ("", "", 0, 0.0, 0, "", "", 0.0, 0.0, 0.0, 0.0)
    @State var diveTable: DiveTable = []
    // Variable is unused \/
    @State var loadingStatus: Bool = false
    @State var loaded: Bool = true
    
    // Shows debug dataset, sets to true if "debug" is request string
    @State private var debugMode: Bool = false
    
    let screenFrame = Color(.systemBackground)
    
    var body: some View {
        ZStack {
            // Only loads WebView if not in debug mode
            if !debugMode {
                if shiftingBool {
                    LRWebView(request: request, html: $html)
                        .onChange(of: html) { newValue in
                            loaded = parseHelper(newValue: newValue)
                        }
                } else {
                    LRWebView(request: request, html: $html)
                        .onChange(of: html) { newValue in
                            loaded = parseHelper(newValue: newValue)
                        }
                }
            }
            
            if loaded {
                mainView(lastDiverInformation: $lastDiverInformation, nextDiverInformation:
                            $nextDiverInformation, diveTable: $diveTable, focusViewList: $focusViewList,
                         starSelected: $starSelected, shiftingBool: $shiftingBool, title: $title,
                         roundString: $roundString)
            } else {
                errorView()
            }
        }
        .onAppear {
            if request == "debug" {
                debugMode = true
            }
            if debugMode {
                lastDiverInformation = DebugDataset.lastDiverInfo
                nextDiverInformation = DebugDataset.nextDiverInfo
                diveTable = DebugDataset.diveTable
                focusViewList = DebugDataset.focusViewDict
                title = DebugDataset.title
                roundString = DebugDataset.roundString
            }
        }
    }
    
    private func parseHelper(newValue: String) -> Bool{
        do {
            diveTable = []
            var upperTables: Elements = Elements()
            var individualTables: Elements = Elements()
            let document: Document = try SwiftSoup.parse(newValue)
            guard let body = document.body() else {
                return false
            }
            let table = try body.getElementById("Results")
            guard let rows = try table?.getElementsByTag("tr") else { return false }
            if rows.count < 9 { return false}
            upperTables = try rows[1].getElementsByTag("tbody")
            
            if upperTables.isEmpty() { return false}
            individualTables = try upperTables[0].getElementsByTag("table")
            
            let linkHead = "https://secure.meetcontrol.com/divemeets/system/"
            
            //Title
            title = try rows[0].getElementsByTag("td")[0].text()
                .replacingOccurrences(of: "Unofficial Statistics ", with: "")
            
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
            
            if individualTables.count < 3 { return false }
            let lastDiverStr = try individualTables[0].text()
            let lastDiver = try individualTables[0].getElementsByTag("a")
            
            if lastDiver.isEmpty() { return false }
            lastDiverName = try lastDiver[0].text()
            // Adds space after name and before team
            if let idx = lastDiverName.firstIndex(of: "(") {
                lastDiverName.insert(" ", at: idx)
            }
            
            var tempLink = try individualTables[0].getElementsByTag("a").attr("href")
            lastDiverProfileLink = linkHead + tempLink
            
            lastRoundPlace = Int(lastDiverStr.slice(from: "Last Round Place: ",
                                                    to: " Last Round") ?? "") ?? 0
            lastRoundTotalScore = Double(lastDiverStr.slice(from: "Last Round Total Score: ",
                                                            to: " Diver O") ?? "") ?? 0.0
            order = Int(lastDiverStr.slice(from: "Diver Order: ", to: " Current") ?? "") ?? 0
            currentPlace = Int(lastDiverStr.slice(from: "Current Place: ",
                                                  to: " Current") ?? "") ?? 0
            currentTotal = Double(lastDiverStr.slice(from: "Current Total Score: ",
                                                     to: " Current") ?? "") ?? 0.0
            currentDive = lastDiverStr.slice(from: "Current Dive:   ", to: " Height") ?? ""
            height = lastDiverStr.slice(from: "Height: ", to: " DD:") ?? ""
            dd = Double(lastDiverStr.slice(from: "DD: ", to: " Score") ?? "") ?? 0.0
            score = Double(lastDiverStr.slice(from: String(dd) + " Score: ",
                                              to: " Judges") ?? "") ?? 0.0
            if let lastIndex = lastDiverStr.lastIndex(of: ":") {
                let distance = lastDiverStr.distance(from: lastIndex,
                                                     to: lastDiverStr.endIndex) - 1
                judgesScores = String(lastDiverStr.suffix(distance - 1))
            }
            lastDiverInformation = (lastDiverName, lastDiverProfileLink, lastRoundPlace,
                                    lastRoundTotalScore, order, currentPlace, currentTotal,
                                    currentDive, height, dd, score, judgesScores)
            
            //Upcoming Diver
            
            var nextDiverName = ""
            var nextDiverProfileLink = ""
            var nextDive = ""
            var avgScore = 0.0
            var maxScore = 0.0
            var forFirstPlace = 0.0
            
            let upcomingDiverStr = try individualTables[2].text()
            let nextDiver = try individualTables[2].getElementsByTag("a")
            
            if nextDiver.isEmpty() { return false }
            nextDiverName = try nextDiver[0].text()
            // Adds space after name and before team
            if let idx = nextDiverName.firstIndex(of: "(") {
                nextDiverName.insert(" ", at: idx)
            }
            
            tempLink = try individualTables[2].getElementsByTag("a").attr("href")
            nextDiverProfileLink = linkHead + tempLink
            
            lastRoundPlace = Int(upcomingDiverStr.slice(from: "Last Round Place: ",
                                                        to: " Last Round") ?? "") ?? 0
            lastRoundTotalScore = Double(upcomingDiverStr.slice(from: "Last Round Total Score: ",
                                                                to: " Diver O") ?? "") ?? 0.0
            order = Int(upcomingDiverStr.slice(from: "Order: ", to: " Next Dive") ?? "") ?? 0
            nextDive = upcomingDiverStr.slice(from: "Next Dive:   ", to: " Height") ?? ""
            height = upcomingDiverStr.slice(from: "Height: ", to: " DD:") ?? ""
            dd = Double(upcomingDiverStr.slice(from: "DD: ", to: " History for") ?? "") ?? 0.0
            avgScore = Double(upcomingDiverStr.slice(from: "Avg Score: ",
                                                     to: "  Max Score") ?? "") ?? 0.0
            maxScore = Double(upcomingDiverStr.slice(from: "Max Score Ever: ",
                                                     to: " Needed") ?? "") ?? 0.0
            var result = ""
            for char in upcomingDiverStr.reversed() {
                if char == " " {
                    break
                }
                result = String(char) + result
            }
            forFirstPlace = Double(result) ?? 999.99
            nextDiverInformation = (nextDiverName, nextDiverProfileLink, lastRoundPlace,
                                    lastRoundTotalScore, order, nextDive, height, dd,
                                    avgScore, maxScore, forFirstPlace)
            
            //Current Round
            let currentRound = try rows[8].getElementsByTag("td")
            
            if currentRound.isEmpty() { return false }
            roundString = try currentRound[0].text()
            
            //Diving Table
            
            for (i, t) in rows.enumerated(){
                if i < rows.count - 1 && i >= 10 {
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
            
        } catch  {
            print("Parsing finished live event failed")
            return false
        }
        return true
    }
}

struct mainView: View {
    @Environment(\.colorScheme) var currentMode
    @Binding var lastDiverInformation:
    (String, String, Int, Double, Int, Int, Double, String, String, Double, Double, String)
    @Binding var nextDiverInformation:
    (String, String, Int, Double, Int, String, String, Double, Double, Double, Double)
    @Binding var diveTable: [[String]]
    @Binding var focusViewList: [String: Bool]
    @Binding var starSelected: Bool
    @Binding var shiftingBool: Bool
    @Binding var title: String
    @Binding var roundString: String
    @State var screenWidth: CGFloat = 0
    @State var screenHeight: CGFloat = 0
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var colors: [Color] = [.blue, .green, .red, .orange]
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    func startTimer() {
        
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { timer in
            shiftingBool.toggle()
        }
    }
    
    var body: some View {
        bgColor.ignoresSafeArea()
        GeometryReader { geometry in
            VStack(spacing: 0.5){
                    if !starSelected {
                        VStack{
                            Text(title)
                                .font(.title2).bold()
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            Text(roundString)
                            TileSwapView(topView: LastDiverView(lastInfo: $lastDiverInformation),
                                         bottomView: NextDiverView(nextInfo: $nextDiverInformation),
                                         width: screenWidth * 0.95,
                                         height: screenHeight * 0.32)
                            .dynamicTypeSize(.xSmall ... .xxxLarge)
                            .padding(.bottom)
                            Text("Live Rankings")
                                .font(.title2).bold()
                                .padding(.top)
                        }
                    }
                    ScalingScrollView(records: diveTable) { (elem) in
                        ResultsBubbleView(elements: elem, focusViewList: $focusViewList)
                    }
            }
            .onChange(of: focusViewList, perform: {[focusViewList] newValue in
                if focusViewList.count == newValue.count{
                    starSelected.toggle()
                }
            })
            .padding(.bottom, maxHeightOffset)
            .padding(.top)
            .animation(.easeOut(duration: 1), value: starSelected)
            .onAppear {
                screenWidth = geometry.size.width
                screenHeight = geometry.size.height
                startTimer()
            }
        }
    }
}

struct errorView: View {
    @Environment(\.colorScheme) var currentMode
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    var body: some View {
        bgColor.ignoresSafeArea()
        Text("Error with LiveResults, Event may have ended already")
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
                    .animation(Animation.easeInOut(duration: 0.5).delay(0.2).repeatForever(autoreverses: true),
                               value: moveRightLeft)
                    .onAppear {
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
    //  name, link, last round place, last round total, order, place, total, dive, height, dd,
    //score total, [judges scores]
    (String, String, Int, Double, Int, Int, Double, String, String, Double, Double, String)
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Custom.lightBlue)
                .cornerRadius(50)
                .shadow(radius: 20)
            VStack{
                Group{
                    HStack{
                        VStack(alignment: .leading){
                            Text(lastInfo.0)
                                .font(.title3).bold()
                            Text("Last Round Place: " + (lastInfo.2 == 0 ? "N/A" : String(lastInfo.2)))
                            Text("Last Round Total: " + String(lastInfo.3))
                            HStack{
                                Text("Order: " + String(lastInfo.4))
                                Text("Place: " + String(lastInfo.5))
                            }
                            Text("Current Total: " + String(lastInfo.6))
                                .font(.headline)
                        }
                        .scaledToFill()
                        .minimumScaleFactor(0.5)
                        .padding()
                        MiniProfileImage(diverID: String(lastInfo.1.utf16.dropFirst(67)) ?? "")
                            .scaledToFit()
                            .padding(.horizontal)
                    }
                    Text(lastInfo.7)
                        .font(.title3)
                        .bold()
                        .scaledToFill()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding([.leading, .trailing])
                    HStack{
                        Text("Height: " + lastInfo.8)
                        Text("DD: " + String(lastInfo.9))
                        Text("Score Total: " + String(lastInfo.10))
                    }
                    .scaledToFit()
                    .minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
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
}

struct NextDiverView: View
{
    @Binding var nextInfo: NextDiverInfo
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Custom.coolBlue)
                .cornerRadius(50)
                .shadow(radius: 20)
            VStack{
                Group{
                    HStack{
                        VStack(alignment: .leading){
                            Text(nextInfo.0)
                                .font(.title3).bold()
                            Text("Last Round Place: " + (nextInfo.2 == 0 ? "N/A" : String(nextInfo.2)))
                            Text("Last Round Total: " + String(nextInfo.3))
                            HStack{
                                Text("Order: " + String(nextInfo.4))
                            }
                        }
                        .scaledToFill()
                        .minimumScaleFactor(0.5)
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
                            .scaledToFill()
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .padding([.leading, .trailing])
                        HStack{
                            Text("Height: " + nextInfo.6)
                            Text("DD: " + String(nextInfo.7))
                        }
                        HStack{
                            Text("Average Score: " + String(nextInfo.8))
                            Text("Max Score: " + String(nextInfo.9))
                        }
                        .scaledToFit()
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(1)
                        Text("For First Place: " + String(nextInfo.10))
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct shiftingTileView: View {
    @Namespace var namespace
    @State var show = false
    
    var body: some View{
        ZStack{
            if !show{
                ScrollView {
                    VStack{
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(
                        Color.red.matchedGeometryEffect(id: "background", in: namespace)
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
                                    .
                                matchedGeometryEffect(id: "blur", in: namespace)
                            )
                            .offset(y: 20)
                            .padding(20)
                    )
                    .frame(height: 200)
                .padding(20)
                }
            } else {
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
                        Color.blue.matchedGeometryEffect(id: "background", in: namespace)
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .matchedGeometryEffect(id: "mask", in: namespace)
                    )
                    .frame(height: 500)
                .padding(20)
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)){
                show.toggle()
            }
        }
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


struct DebugDataset {
    //  name, link, last round place, last round total, order, place, total, dive, height, dd,
    //score total, [judges scores]
    static let lastDiverInfo: LastDiverInfo =
    ("Diver 1", "https://secure.meetcontrol.com/divemeets/system/profile.php?number=56961", 1,
     225.00, 1, 1, 175.00, "5337D - Reverse 1 1/2 Somersaults 3 1/2 Twist", "3M", 3.3, 69.3, "7.0 | 7.0 | 7.0")
    //nextDiverName, nextDiverProfileLink, lastRoundPlace, lastRoundTotalScore, order, nextDive,
    //height, dd, avgScore, maxScore, forFirstPlace
    static let nextDiverInfo: NextDiverInfo =
    ("Diver 2", "https://secure.meetcontrol.com/divemeets/system/profile.php?number=56961", 3,
     155.75, 2, "307C", "3M", 3.5, 55.0, 105.0, 69.25)
    
    //                    [[Left to dive, order, last round place, last round score, current place,
    //                      current score, name, link, last dive average, event average score, avg round score]]
    static let diver1: [String] = ["true", "1", "1", "175.00", "1", "225.00", "Diver 1",
                                   "https://secure.meetcontrol.com/divemeets/system/profile.php?number=56961",
                                   "7.0", "6.5", "55.5"]
    static let diver2: [String] = ["false", "2", "3", "155.75", "3", "155.75", "Diver 2",
                                   "https://secure.meetcontrol.com/divemeets/system/profile.php?number=56961",
                                   "6.0", "5.7", "41.7"]
    static let diver3: [String] = ["false", "3", "2", "158.20", "2", "158.20", "Diver 3",
                                   "https://secure.meetcontrol.com/divemeets/system/profile.php?number=56961",
                                   "6.5", "6.1", "45.3"]
    static let diver4: [String] = ["false", "4", "4", "111.65", "4", "111.65", "Diver 4",
                                   "https://secure.meetcontrol.com/divemeets/system/profile.php?number=56961",
                                   "4.5", "4.8", "37.4"]
    
    static let diveTable: DiveTable = [diver1, diver3, diver2, diver4]
    static let focusViewDict: [String: Bool] = [diver1[6]: false, diver2[6]: false,
                                                diver3[6]: false, diver4[6]: false]
    static let title: String = "Debug Live Results View"
    static let roundString: String = "Round: 3 / 6"
}
