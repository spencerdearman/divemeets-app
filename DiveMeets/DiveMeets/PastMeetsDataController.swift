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
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load PastMeets: \(error.localizedDescription)")
            }
        }
    }
}
