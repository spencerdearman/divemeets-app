//
//  MeetsDataController.swift
//  PastMeets
//
//  Created by Logan Sherwin on 4/3/23.
//

import CoreData
import Foundation

enum RecordType: Int, CaseIterable {
    case upcoming = 0
    case current = 1
    case past = 2
    
}

//                      id  , name   , org    , link   , startDate, endDate, city , state  , country
typealias MeetRecord = (Int?, String?, String?, String?, String?, String?, String?, String?, String?)

class MeetsDataController: ObservableObject {
    let container = NSPersistentContainer(name: "Meets")
    static var instances: Int? = nil
    
    init() {
        // Attempted guard at creating more than one instance of class
        if MeetsDataController.instances == nil {
            MeetsDataController.instances = 1
            container.loadPersistentStores { description, error in
                if let error = error {
                    print("Core Data failed to load Meets: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Adds a single record to the CoreData database if not already present
    func addRecord(_ meetId: Int?, _ name: String?, _ org: String?, _ link: String?,
                   _ startDate: String?, _ endDate: String?, _ city: String?, _ state: String?,
                   _ country: String?, _ type: RecordType?) {
        let moc = container.viewContext
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        var startDateN: NSDate?
        var endDateN: NSDate?
        if startDate != nil {
            startDateN = df.date(from: startDate!) as? NSDate
        } else {
            startDateN = nil
        }
        if endDate != nil {
            endDateN = df.date(from: endDate!) as? NSDate
        } else {
            endDateN = nil
        }
        
        // Check if the entry is already in the database before adding
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
        
        // Add formatting here so we can properly format nil if meetId or year is nil
        let formatPredicate =
        "meetId == \(meetId == nil ? "%@" : "%d") AND name == %@ AND "
        + "link == %@ AND startDate == %@ AND endDate == %@ AND city == %@ AND state == %@ AND "
        + "country == %@"
        // Formatting for post-typechecking refetch
        let postTypeCheckFormatPredicate =
        "meetId == \(meetId == nil ? "%@" : "%d") AND name == %@ AND organization == %@ AND "
        + "link == %@ AND startDate == %@ AND endDate == %@ AND city == %@ AND state == %@ AND "
        + "country == %@"
        // Cannot match on organization because meet status changes organization
        let predicate = NSPredicate(
            format: formatPredicate, meetId ?? NSNull(), name ?? NSNull(),
            link ?? NSNull(), startDateN ?? NSNull(), endDateN ?? NSNull(), city ?? NSNull(),
            state ?? NSNull(), country ?? NSNull())
        let postTypeCheckPredicate = NSPredicate(
            format: postTypeCheckFormatPredicate, meetId ?? NSNull(), name ?? NSNull(), org ?? NSNull(),
            link ?? NSNull(), startDateN ?? NSNull(), endDateN ?? NSNull(), city ?? NSNull(),
            state ?? NSNull(), country ?? NSNull())
        fetchRequest.predicate = predicate
        
        var result = try? moc.fetch(fetchRequest)
        
        // Deletes all meets that match in every field but organization and type and deletes all
        // meets that have a lower type value (upcoming < current < past)
        if result!.count > 0 {
            let resultData = result as! [DivingMeet]
            for meet in resultData {
                if type != nil && Int(meet.meetType) < type!.rawValue {
                    moc.delete(meet)
                }
            }
        }
        
        // Refetch results after removing above, including organization
        fetchRequest.predicate = postTypeCheckPredicate
        result = try? moc.fetch(fetchRequest)
        
        // Only adds to the database if it couldn't be found already (exact duplicates)
        if result!.count == 0 {
            let meet = DivingMeet(context: moc)
            
            meet.id = UUID()
            if meetId != nil {
                meet.meetId = Int32(meetId!)
            }
            meet.name = name
            meet.organization = org
            meet.link = link
            if type != nil {
                meet.meetType = Int16(type!.rawValue)
            }
            if startDate != nil {
                meet.startDate = df.date(from: startDate!)
            }
            if endDate != nil {
                meet.endDate = df.date(from: endDate!)
            }
            meet.city = city
            meet.state = state
            meet.country = country
            
            try? moc.save()
        }
    }
    
    // Adds a list of records to the CoreData database
    func addRecords(records: [MeetRecord], type: RecordType? = nil) {
        for record in records {
            let (meetId, name, org, link, startDate, endDate, city, state, country) = record
            addRecord(meetId, name, org, link, startDate, endDate, city, state, country, type)
        }
    }
    
    // Drops a record from the CoreData database
    func dropRecord(_ meetId: Int?, _ name: String?, _ org: String?, _ link: String?,
                    _ startDate: String?, _ endDate: String?, _ city: String?, _ state: String?,
                    _ country: String?) {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        var startDateN: NSDate? = nil
        var endDateN: NSDate? = nil
        if startDate != nil {
            startDateN = df.date(from: startDate!) as? NSDate
        }
        if endDate != nil {
            endDateN = df.date(from: endDate!) as? NSDate
        }
        
        // Add formatting here so we can properly format nil if meetId or year is nil
        let formatPredicate =
        "meetId == \(meetId == nil ? "%@" : "%d") AND name == %@ AND organization == %@ AND "
        + "link == %@ AND startDate == %@ AND endDate == %@ AND city == %@ AND state == %@ AND "
        + "country == %@"
        let predicate = NSPredicate(
            format: formatPredicate, meetId ?? NSNull(), name ?? NSNull(), org ?? NSNull(),
            link ?? NSNull(), startDateN ?? NSNull(), endDateN ?? NSNull(), city ?? NSNull(),
            state ?? NSNull(), country ?? NSNull())
        fetchRequest.predicate = predicate
        
        let result = try? moc.fetch(fetchRequest)
        let resultData = result as! [DivingMeet]
        
        for object in resultData {
            moc.delete(object)
        }
        
        try? moc.save()
    }
    
    // Drops a list of records from the CoreData database
    func dropRecords(records: [MeetRecord]) {
        for record in records {
            let (meetId, name, org, link, startDate, endDate, city, state, country) = record
            dropRecord(meetId, name, org, link, startDate, endDate, city, state, country)
        }
    }
    
    func dropNullOrgRecords() {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
        
        // Add formatting here so we can properly format nil if meetId or year is nil
        let predicate = NSPredicate(format: "organization == nil")
        fetchRequest.predicate = predicate
        
        let result = try? moc.fetch(fetchRequest)
        let resultData = result as! [DivingMeet]
        
        for object in resultData {
            moc.delete(object)
        }
        
        try? moc.save()
    }
    
    // Drops all records from the database
    func dropAllRecords() {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
        
        let result = try? moc.fetch(fetchRequest)
        let resultData = result as! [DivingMeet]
        
        for object in resultData {
            moc.delete(object)
        }
        
        try? moc.save()
    }
    
    // Turns MeetDict into [(meetId, name, org, link, startDate, endDate, city, state, country)]
    func dictToTuple(dict: MeetDict) -> [MeetRecord] {
        var result: [MeetRecord] = []
        for (_, orgDict) in dict {
            for (org, meetDict) in orgDict {
                for (name, link, startDate, endDate, city, state, country) in meetDict {
                    let meetId: Int = Int(link.split(separator: "=").last!)!
                    result.append(
                        (meetId, name, org, link, startDate, endDate, city, state, country))
                }
            }
        }
        
        return result
    }
    
    // Turns CurrentMeetDict into
    // [(meetId, name, <nil>, link, startDate, endDate, city, state, country)]
    // ** link is info link for meet, results link is not stored in the database if it exists
    func dictToTuple(dict: CurrentMeetList) -> [MeetRecord] {
        var result: [MeetRecord] = []
        for elem in dict {
            for (name, typeDict) in elem {
                for (typ, (link, startDate, endDate, city, state, country)) in typeDict {
                    if typ == "results" {
                        continue
                    }
                    let meetId: Int = Int(link.split(separator: "=").last!)!
                    result.append(
                        (meetId, name, nil, link, startDate, endDate, city, state, country))
                }
            }
        }
        
        return result
    }
}
