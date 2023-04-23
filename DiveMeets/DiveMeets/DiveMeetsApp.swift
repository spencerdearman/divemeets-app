//
//  DiveMeetsApp.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

private struct PastMeetsDB: EnvironmentKey {
    static var defaultValue: MeetsDataController {
        get {
            MeetsDataController()
        }
    }
}

extension EnvironmentValues {
    var pastMeetsDB: MeetsDataController {
        get { self[PastMeetsDB.self] }
        set { self[PastMeetsDB.self] = newValue }
    }
}

extension View {
    func pastMeetsDB(_ pastMeetsDB: MeetsDataController) -> some View {
        environment(\.pastMeetsDB, pastMeetsDB)
    }
}

@main
struct DiveMeetsApp: App {
    // Only one of these should exist, add @Environment to use variable in views
    // instead of creating a new instance of MeetsDataController()
    @StateObject var MeetsDataController = MeetsDataController()
    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.managedObjectContext, MeetsDataController.container.viewContext).environment(\.pastMeetsDB, MeetsDataController)
        }
    }
}
