import Foundation
import Contacts
import CoreData
import UserNotifications

class ContactManager: ObservableObject {
    private let store = CNContactStore()
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func loadContactsFromAddressBook() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            saveContactsToCoreData()
            scheduleNotifications()
        case .notDetermined:
            store.requestAccess(for: .contacts) { granted, error in
                if granted {
                    DispatchQueue.main.async {
                        self.saveContactsToCoreData()
                        self.scheduleNotifications()
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
    
    private func scheduleNotification(for contact: Contact) {
        guard let birthday = contact.birthday else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Birthday Reminder"
        content.body = "It's \(contact.name ?? "someone")'s birthday today!"
        content.sound = .default
        
        // Get the date components for the next birthday at 9:00 AM.
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: birthday)
        dateComponents.hour = 8
        
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
    
}
