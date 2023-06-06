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
    @State var request: String =
    "https://secure.meetcontrol.com/divemeets/system/livestats.php?event=stats-9037-3470-9-Started"
    @State var html: String = ""
    @State var rows: [[String: String]] = []
    @State var columns: [String] = []
    @State private var moveRightLeft = false
    @State var lastDiverInformation:
    //  name, link, last round place, last round total, order, place, total, dive, height, dd, score total, [judges scores]
    (String, String, Int, Double, Int, Int, Double, String, String, Double, Double, String) =
    ("", "", 0, 0.0, 0, 0, 0.0, "", "", 0.0, 0.0, "")
    @State var nextDiverInformation: (String, String, Int, Double, Int, String, String, Double, Double, Double, Double) = ("", "", 0, 0.0, 0, "", "", 0.0, 0.0, 0.0, 0.0)
    let screenFrame = Color(.systemBackground)
    
    var body: some View {
        ZStack {
            LRWebView(request: $request, html: $html)
                .onChange(of: html) { newValue in
                    var result: LiveResults = LiveResults(meetName: "Test",
                                                          eventName: "Test Event",
                                                          link: request,
                                                          isFinished: true)
                    
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
                    } catch  {
                        print("Parsing finished live event failed")
                    }
                }
            
            Color.white.ignoresSafeArea()
            VStack{
                LiveBarAnimation()
                //LoadingThreeBallsTriangle()
                Spacer()
                LastDiverView(lastInfo: $lastDiverInformation)
                    .frame(width: 400, height: 300) // Adjust the size as per your requirement
                    .background(Color.blue) // Bubble color
                    .cornerRadius(40) // Rounded corners
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2) // Shadow effect
                Spacer()
                //LiveBarAnimation()
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

struct LoadingThreeBallsTriangle: View {
    
    @State var isAnimating: Bool = false
    let timing: Double
    
    let maxCounter = 3
    
    let frame: CGSize
    let primaryColor: Color

    init(color: Color = .black, size: CGFloat = 50, speed: Double = 0.5) {
        timing = speed * 2
        frame = CGSize(width: size, height: size)
        primaryColor = color
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(primaryColor)
                .frame(height: frame.height / 3)
                .offset(
                    x: 0,
                    y: isAnimating ? -frame.height / 3 : 0)

            Circle()
                .fill(primaryColor)
                .frame(height: frame.height / 3)
                .offset(
                    x: isAnimating ? -frame.height / 3 : 0,
                    y: isAnimating ? frame.height / 3 : 0)

            Circle()
                .fill(primaryColor)
                .frame(height: frame.height / 3)
                .offset(
                    x: isAnimating ? frame.height / 3 : 0,
                    y: isAnimating ? frame.height / 3 : 0)
        }
        .animation(Animation.easeInOut(duration: timing).repeatForever(autoreverses: true))
        .frame(width: frame.width, height: frame.height, alignment: .center)
        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
        .animation(Animation.easeInOut(duration: timing).repeatForever(autoreverses: false))
        .onAppear {
            isAnimating = true
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
                    VStack{
                        Text("Name: " + lastInfo.0)
                        Text("Last Round Place: " + String(lastInfo.2))
                        Text("Last Round Total: " + String(lastInfo.3))
                        HStack{
                            Text("Order: " + String(lastInfo.4))
                            Text("Place: " + String(lastInfo.5))
                        }
                        Text("Current Total: " + String(lastInfo.6))
                            .font(.headline)
                    }
                    MiniProfileImage(diverID: String(lastInfo.1.utf16.dropFirst(67)) ?? "")
                        .scaledToFit()
                }
                Text("Dive: " + lastInfo.7)
                HStack{
                    Text("Height: " + lastInfo.8)
                    Text("DD: " + String(lastInfo.9))
                    Text("Score Total: " + String(lastInfo.10))
                }
                //Text("Link: " + lastInfo.1)
            }
            Group{
                Text("Judges Scores")
                    .underline()
                Text(lastInfo.11)
                    .font(.headline)
            }
            //Text("Score Total: " + String(lastInfo.10))
            //Text("Judges Scores: " + lastInfo.11)
        }
    }
}
