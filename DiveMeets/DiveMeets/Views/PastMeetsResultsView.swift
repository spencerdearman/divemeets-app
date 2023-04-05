//
//  PastMeetsResultsView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/3/23.
//

import SwiftUI
import CoreData

struct PastMeetsResultsView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.pastMeetsDB) var db
    @StateObject private var getTextModel = GetTextAsyncModel()
    @StateObject private var p = MeetParser()
    @State var finishedParsing: Bool = false
    
    @FetchRequest(sortDescriptors: []) var meets: FetchedResults<DivingMeet>
    // Note: predicate formats use %@ for strings instead of %s, still use %d for ints
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "%@ in name AND year > %d", "Zone", 2019)
    ) var filteredMeets: FetchedResults<DivingMeet>
    
    func displayDivingMeet(meet: DivingMeet) -> HStack<TupleView<(Text, Text, Text, Text)>> {
        let linkHead = "https://secure.meetcontrol.com/divemeets/system/"
        return HStack {
            Text(meet.name ?? "Unknown")
            Text(meet.organization ?? "Unknown")
            Text(String(meet.year))
            Text(meet.link != nil ? meet.link![meet.link!.index(meet.link!.startIndex, offsetBy: linkHead.count)..<meet.link!.endIndex] : "Unknown")
        }
    }
    
    func displayDivingMeets(meets: FetchedResults<DivingMeet>) -> any View {
        return List(meets) { meet in
            displayDivingMeet(meet: meet)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                /*
//                Button("Add") {
//                    let meet = DivingMeet(context: moc)
//
//                    let (name, org, year, link) = testMeets.randomElement()!
//
//                    meet.id = UUID()
//                    meet.name = name
//                    meet.organization = org
//                    meet.year = Int16(year)
//                    meet.link = link
//
//                    try? moc.save()
//                }
//                Spacer()
//                Button("Remove") {
//                    for meet in meets.reversed() {
//                        moc.delete(meet as NSManagedObject)
//                        try? moc.save()
//                        break
//                    }
//                }
//                Spacer()
//                Button("Add List") {
//                    db.addRecords(records: testMeets)
//                }
//                Spacer()
//                Button("Drop List") {
//                    db.dropRecords(records: testMeets)
//                }
                 */
                Button("Drop All") {
                    db.dropAllRecords()
                }
                Spacer()
            }
            .padding()
            HStack {
                Spacer()
                Button("Run") {
                    let url = URL(string: "https://secure.meetcontrol.com/divemeets/system/index.php")!
                    
                    Task {
                        finishedParsing = false
                        // This sets getTextModel's text field equal to the HTML from url
                        await getTextModel.fetchText(url: url)
                        // This sets p's upcoming, current, and past meets fields
                        try await p.parseMeets(html: getTextModel.text!)
                        finishedParsing = true
                        print("Finished parsing")
                    }
                    
                }
                Spacer()
                if finishedParsing {
                    Button("Print") {
                        print(p.upcomingMeets ?? [:])
                        print(p.currentMeets ?? "")
                        p.printPastMeets()
                    }
                    Spacer()
                    Button("Tuples") {
                        if finishedParsing {
                            print("Upcoming:", db.dictToTuple(dict: p.upcomingMeets!))
                            let past = db.dictToTuple(dict: p.pastMeets!)
                            let left = past[0 ..< past.count / 2]
                            let right = past[past.count / 2 ..< past.count]
                            
                            print("Past: [")
                            for k in left {
                                print(k, ",")
                            }
                            for k in right {
                                print(k, ",")
                            }
                            print("]")
                        } else {
                            print([(String, String, Int, String)]())
                        }
                    }
                    Spacer()
                    Button("Add Upcoming") {
                        if finishedParsing {
                            db.addRecords(records: db.dictToTuple(dict: p.upcomingMeets!))
                        }
                    }
                    Spacer()
                    Button("Add Past") {
                        if finishedParsing {
                            db.addRecords(records: db.dictToTuple(dict: p.pastMeets!))
                        }
                    }
                    Spacer()
                }
            }.padding()
            
            List(meets) { meet in
                displayDivingMeet(meet: meet)
            }
            
            List(filteredMeets) { meet in
                displayDivingMeet(meet: meet)
            }
            
        }
    }
}

struct PastMeetsResultsView_Previews: PreviewProvider {
    static var previews: some View {
        PastMeetsResultsView()
    }
}
