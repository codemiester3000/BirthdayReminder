// BirthdayReminderApp.swift

import SwiftUI

@main
struct BirthdayReminderApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var isActive: Bool = false
    @State private var presentingMessageComposer: Bool = false
    @State private var recipientNumber: String = ""
    @State private var messageBody: String = ""

    var body: some Scene {
        WindowGroup {
            ContactListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .sheet(isPresented: $presentingMessageComposer) {
                    MessageComposer(recipientNumber: recipientNumber, messageBody: messageBody, presented: $presentingMessageComposer)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    if isActive {
                        // check if there's a phone number and a message stored
                        if let phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber"),
                        let message = UserDefaults.standard.string(forKey: "message") {
                            recipientNumber = phoneNumber
                            messageBody = message
                            presentingMessageComposer = true
                        }
                        isActive = false
                    } else {
                        isActive = true
                    }
                }
        }
    }
}
