import Foundation
import Contacts
import CoreData
import UserNotifications
import EventKit

class ContactManager: ObservableObject {
    private let store = CNContactStore()
    private let viewContext: NSManagedObjectContext
    private let eventStore = EKEventStore()
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    private func scheduleNotification(for contact: Contact) {
        guard let birthday = contact.birthday else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Birthday Reminder"
        content.body = "It's \(contact.name ?? "someone")'s birthday today!"
        content.sound = .default
        content.userInfo = ["phoneNumber": "7039736936" ?? "", "message": contact.message ?? ""]
        
        // Get the date components for the next birthday at 9:00 AM.
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: birthday)
        dateComponents.hour = 20
        dateComponents.minute = 51 
        
        // Extract day and month from current date and birthday
        let currentDayAndMonth = Calendar.current.dateComponents([.day, .month], from: Date())
        let birthdayDayAndMonth = Calendar.current.dateComponents([.day, .month], from: birthday)
        
        // Compare only day and month, if birthday has already passed this year, schedule for next year
        if birthdayDayAndMonth.month! < currentDayAndMonth.month! ||
            (birthdayDayAndMonth.month! == currentDayAndMonth.month! && birthdayDayAndMonth.day! < currentDayAndMonth.day!) {
            dateComponents.year! += 1
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    func loadContactsFromAddressBook() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            saveContactsToCoreData()
            requestCalendarAccess { granted in
                if granted {
                    self.updateBirthdaysFromCalendar()
                    self.scheduleNotifications()
                }
            }
        case .notDetermined:
            store.requestAccess(for: .contacts) { granted, error in
                if granted {
                    DispatchQueue.main.async {
                        self.saveContactsToCoreData()
                        self.requestCalendarAccess { granted in
                            if granted {
                                self.updateBirthdaysFromCalendar()
                                self.scheduleNotifications()
                            }
                        }
                    }
                } else {
                    // Handle the error.
                }
            }
        case .denied, .restricted:
            // The user has denied access. Handle this situation as appropriate for your app.
            break
        @unknown default:
            break
        }
    }
    
    func saveContactsToCoreData() {
        let keysToFetch = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor
        ]
        
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        do {
            try store.enumerateContacts(with: request) {
                (contact, stop) in
                let name = contact.givenName + " " + contact.familyName
                var birthday: Date? = nil
                
                if let birthdayComponents = contact.birthday {
                    birthday = Calendar.current.date(from: birthdayComponents)
                }
                
                let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "name == %@", name)
                
                let existingContacts = try? self.viewContext.fetch(fetchRequest)
                
                if existingContacts?.isEmpty ?? true {
                    let newContact = Contact(context: self.viewContext)
                    newContact.name = name
                    newContact.birthday = birthday
                    newContact.message = birthday != nil ? "Happy Birthday!" : ""
                    
                    do {
                        try self.viewContext.save()
                    } catch {
                        print("Failed to save contact, error: \(error)")
                    }
                }
            }
        } catch {
            print("Failed to fetch contact, error: \(error)")
        }
    }
    
    func scheduleNotifications() {
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        if let contacts = try? viewContext.fetch(fetchRequest) {
            for contact in contacts {
                scheduleNotification(for: contact)
            }
        }
    }
    
    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            completion(true)
        case .notDetermined:
            eventStore.requestAccess(to: .event) { (granted: Bool, error: Error?) -> Void in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    func updateBirthdaysFromCalendar() {
        // Specify the start and end dates for your fetch
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        let predicate = eventStore.predicateForEvents(withStart: Date(), end: oneYearFromNow, calendars: nil)
        
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            if event.title.hasPrefix("Birthday: ") {
                let name = String(event.title.dropFirst(9)) // remove "Birthday: " prefix
                let birthday = event.startDate
                
                let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "name == %@", name)
                
                let existingContacts = try? self.viewContext.fetch(fetchRequest)
                
                if let contact = existingContacts?.first {
                    contact.birthday = birthday
                } else {
                    let newContact = Contact(context: self.viewContext)
                    newContact.name = name
                    newContact.birthday = birthday
                    newContact.message = "Happy Birthday!"
                }
            }
        }
        
        do {
            try self.viewContext.save()
        } catch {
            print("Failed to save contact, error: \(error)")
        }
    }
}
