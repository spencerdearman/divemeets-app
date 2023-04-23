//
//  MeetsResultsView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/3/23.
//

import SwiftUI
import CoreData

struct MeetsResultsView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.meetsDB) var db
    @State var liveResultsLink: String = ""
    @State var liveResultHTML: String = ""
    @State var finishedParsing: Bool = false
    
    @StateObject private var getTextModel = GetTextAsyncModel()
    @StateObject private var p = MeetParser()
    
    
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "meetId", ascending: false)]
    ) var meets: FetchedResults<DivingMeet>
    // Note: predicate formats use %@ for strings instead of %s, still use %d for ints
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(
            format: "%@ in[cd] name && year < %d", "Big Dive", 2013)
    ) var filteredMeets: FetchedResults<DivingMeet>
    
    func displayDivingMeet(meet: DivingMeet) -> HStack<TupleView<(Text, Text, Text, Text, Text)>> {
        let linkHead = "https://secure.meetcontrol.com/divemeets/system/"
        return HStack {
            Text(String(meet.meetId))
            Text(meet.name ?? "Unknown")
            Text(meet.organization ?? "Unknown")
            Text(String(meet.year))
            Text(meet.link != nil
                 ? meet.link![meet.link!.index(
                    meet.link!.startIndex, offsetBy: linkHead.count)..<meet.link!.endIndex]
                 : "Unknown")
        }
    }
    
    func displayDivingMeets(meets: FetchedResults<DivingMeet>) -> any View {
        return List(meets) { meet in
            displayDivingMeet(meet: meet)
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Button("Drop All") {
                        db.dropAllRecords()
                    }
                    Spacer()
                }
                .padding()
                HStack {
                    if !finishedParsing {
                        Button("Run") {
                            let url = URL(
                                string: "https://secure.meetcontrol.com/divemeets/system/index.php")!
                            
                            Task {
                                finishedParsing = false
                                // This sets getTextModel's text field equal to the HTML from url
                                await getTextModel.fetchText(url: url)
                                if let text = getTextModel.text {
                                    // This sets p's upcoming, current, and past meets fields
                                    try await p.parseMeets(html: text, storedMeets: meets)
                                    finishedParsing = true
                                    print("Finished parsing")
                                } else {
                                    print("Could not get text from URL")
                                }
                            }
                            
                        }
                        Spacer()
                        Button("Drop nil orgs") {
                            db.dropNullOrgRecords()
                        }
                    } else {
                        Spacer()
                        Button("Print") {
                            print("Upcoming:\n", p.upcomingMeets ?? [:])
                            print("Current:\n", p.currentMeets ?? [])
                            print("Past:")
                            p.printPastMeets()
                        }
                        Spacer()
                        Button("Tuples") {
                            if finishedParsing {
                                print("Upcoming:", db.dictToTuple(dict: p.upcomingMeets ?? [:]))
                                print("Current:", db.dictToTuple(dict: p.currentMeets ?? []))
                                if p.pastMeets != nil {
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
                                }
                            } else {
                                print([(Int, String, String, Int, String)]())
                            }
                        }
                        Spacer()
                        Button("Add Upcoming") {
                            if finishedParsing {
                                db.addRecords(records: db.dictToTuple(dict: p.upcomingMeets!))
                            }
                        }
                        Spacer()
                        Button("Add Current") {
                            if finishedParsing {
                                db.addRecords(records: db.dictToTuple(dict: p.currentMeets!))
                            }
                        }
                        Spacer()
                        Button("Add Past") {
                            if finishedParsing {
                                db.addRecords(records: db.dictToTuple(dict: p.pastMeets!))
                            }
                        }
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
}
