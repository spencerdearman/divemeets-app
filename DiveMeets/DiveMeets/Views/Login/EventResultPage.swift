//
//  EventResultPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/26/23.
//

import SwiftUI


struct EvemtResultsPage: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}


//struct EventResultPage: View {
//    @StateObject private var parser = EventPageHTMLParser()
//    @State var meetLink: String = "https://secure.meetcontrol.com/divemeets/system/eventresultsext.php?meetnum=7925&eventnum=1010&eventtype=9"
//    @State var resultData: [Int: (String, String, String, Double, String)] = [:]
//
//    var body: some View {
//        ZStack{}
//            .onAppear {
//                Task {
//                    await parser.parse(urlString: meetLink)
//                    resultData = parser.eventPageData
//                }
//            }
//    }
//}
//
//struct EventResultPage_Previews: PreviewProvider {
//    static var previews: some View {
//        EventResultPage()
//    }
//}
