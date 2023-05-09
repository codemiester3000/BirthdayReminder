//
//  BirthdayReminderApp.swift
//  BirthdayReminder
//
//  Created by Owen Khoury on 5/9/23.
//

import SwiftUI

@main
struct BirthdayReminderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
