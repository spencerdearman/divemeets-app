//
//  PastMeetsDataController.swift
//  PastMeets
//
//  Created by Logan Sherwin on 4/3/23.
//

import CoreData
import Foundation

class PastMeetsDataController: ObservableObject {
    let container = NSPersistentContainer(name: "PastMeets")
    static var instances: Int? = nil
    
    init() {
        // Attempted guard at creating more than one instance of class
        if PastMeetsDataController.instances == nil {
            PastMeetsDataController.instances = 1
            container.loadPersistentStores { description, error in
                if let error = error {
                    print("Core Data failed to load PastMeets: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Adds a single record to the CoreData database
    func addRecord(_ name: String, _ org: String, _ year: Int, _ link: String) {
        let moc = container.viewContext
        let meet = DivingMeet(context: moc)
        meet.id = UUID()
        meet.name = name
        meet.organization = org
        meet.year = Int16(year)
        meet.link = link
        
        try? moc.save()
    }
    
    // Adds a list of records to the CoreData database
    func addRecords(records: [(String, String, Int, String)]) {
        for record in records {
            let (name, org, year, link) = record
            addRecord(name, org, year, link)
        }
    }
    
    // Drops a record from the CoreData database
    func dropRecord(_ name: String, _ org: String, _ year: Int, _ link: String) {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
        let predicate = NSPredicate(
            format: "name == %@ AND organization == %@ AND year == %d AND link == %@",
            name, org, year, link)
        fetchRequest.predicate = predicate
        
        let result = try? moc.fetch(fetchRequest)
        let resultData = result as! [DivingMeet]
        
        for object in resultData {
            moc.delete(object)
        }
        
        try? moc.save()
    }
    
    // Drops a list of records from the CoreData database
    func dropRecords(records: [(String, String, Int, String)]) {
        for record in records {
            let (name, org, year, link) = record
            dropRecord(name, org, year, link)
        }
    }
    
    // Turns MeetDict into [(name, org, year, link)]
    func dictToTuple(dict: MeetDict) -> [(String, String, Int, String)] {
        var result: [(String, String, Int, String)] = []
        for (year, orgDict) in dict {
            for (org, meetDict) in orgDict {
                for (name, link) in meetDict {
                    result.append((name, org, Int(year)!, link))
                }
            }
        }
        
        return result
    }
}
