//
//  DiveMeetsApp.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

@main
struct DiveMeetsApp: App {
    @StateObject var pastMeetsDataController = PastMeetsDataController()
    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.managedObjectContext, pastMeetsDataController.container.viewContext)
        }
    }
}
