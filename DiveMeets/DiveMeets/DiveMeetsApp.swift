//
//  DiveMeetsApp.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

private struct MeetsDB: EnvironmentKey {
    static var defaultValue: MeetsDataController {
        get {
            MeetsDataController()
        }
    }
}

extension EnvironmentValues {
    var meetsDB: MeetsDataController {
        get { self[MeetsDB.self] }
        set { self[MeetsDB.self] = newValue }
    }
}

extension View {
    func meetsDB(_ meetsDB: MeetsDataController) -> some View {
        environment(\.meetsDB, meetsDB)
    }
}

@main
struct DiveMeetsApp: App {
    // Only one of these should exist, add @Environment to use variable in views
    // instead of creating a new instance of MeetsDataController()
    @StateObject var meetsDataController = MeetsDataController()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, meetsDataController.container.viewContext)
                .environment(\.meetsDB, meetsDataController)
        }
    }
}
