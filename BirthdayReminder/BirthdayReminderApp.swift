// BirthdayReminderApp.swift

import SwiftUI

@main
struct BirthdayReminderApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContactListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
