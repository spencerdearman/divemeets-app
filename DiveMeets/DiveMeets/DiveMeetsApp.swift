//
//  DiveMeetsApp.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

private struct PastMeetsDB: EnvironmentKey {
    static var defaultValue: PastMeetsDataController {
        get {
            PastMeetsDataController()
        }
    }
}

extension EnvironmentValues {
    var pastMeetsDB: PastMeetsDataController {
        get { self[PastMeetsDB.self] }
        set { self[PastMeetsDB.self] = newValue }
    }
}

extension View {
    func pastMeetsDB(_ pastMeetsDB: PastMeetsDataController) -> some View {
        environment(\.pastMeetsDB, pastMeetsDB)
    }
}

@main
struct DiveMeetsApp: App {
    // Only one of these should exist, add @Environment to use variable in views
    // instead of creating a new instance of PastMeetsDataController()
    @StateObject var pastMeetsDataController = PastMeetsDataController()
    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.managedObjectContext, pastMeetsDataController.container.viewContext).environment(\.pastMeetsDB, pastMeetsDataController)
        }
    }
}
