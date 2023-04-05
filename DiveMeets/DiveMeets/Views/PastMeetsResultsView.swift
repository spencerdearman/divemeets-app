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
        predicate: NSPredicate(format: "name beginswith %@ AND year > %d", "Phoenix", 2020)
    ) var filteredMeets: FetchedResults<DivingMeet>
    
    func displayDivingMeet(meet: DivingMeet) -> HStack<TupleView<(Text, Text, Text, Text)>> {
        return HStack {
            Text(meet.name ?? "Unknown")
            Text(meet.organization ?? "Unknown")
            Text(String(meet.year))
            Text(meet.link ?? "Unknown")
        }
    }
    
    func displayDivingMeets(meets: FetchedResults<DivingMeet>) -> any View {
        return List(meets) { meet in
            displayDivingMeet(meet: meet)
        }
    }
    
    var body: some View {
        let testMeets = [("Phoenix Fall Classic", "NCAA", 2022, "https://secure.meetcontrol.com/divemeets/system/meetresultsext.php?meetnum=8410"),
                         ("Zone A Championships", "USA Diving", 2018, "https://secure.meetcontrol.com/divemeets/system/meetresultsext.php?meetnum=5363"),
                         ("Alexandria Invite", "AAU", 2017, "https://secure.meetcontrol.com/divemeets/system/meetresultsext.php?meetnum=5105")]
        VStack {
            HStack {
                Button("Add") {
                    let meet = DivingMeet(context: moc)
                    
                    let (name, org, year, link) = testMeets.randomElement()!
                    
                    meet.id = UUID()
                    meet.name = name
                    meet.organization = org
                    meet.year = Int16(year)
                    meet.link = link
                    
                    try? moc.save()
                }
                
                Button("Remove") {
                    for meet in meets.reversed() {
                        moc.delete(meet as NSManagedObject)
                        try? moc.save()
                        break
                    }
                }
                
                Button("Add List") {
                    db.addRecords(records: testMeets)
                }
                
                Button("Drop List") {
                    db.dropRecords(records: testMeets)
                }
                
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
                Button("Print") {
                    print(p.upcomingMeets ?? [:])
                    print(p.currentMeets ?? "")
                    p.printPastMeets()
                }
            }
            
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
