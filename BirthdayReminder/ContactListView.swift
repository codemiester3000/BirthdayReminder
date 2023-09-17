import SwiftUI
import Contacts
import CoreData
import UIKit

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("Search...", text: $text)
                .font(.system(size: 16))
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !text.isEmpty {
                            Button(action: { text = "" }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
    }
}

struct ContactListView: View {
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(
        entity: Contact.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Contact.birthday, ascending: false),
            NSSortDescriptor(keyPath: \Contact.name, ascending: true)
        ]
    )
    var contacts: FetchedResults<Contact>
    
    @State private var searchQuery = ""
    @StateObject private var contactManager: ContactManager
    
    init() {
        _contactManager = StateObject(wrappedValue: ContactManager(viewContext: PersistenceController.shared.container.viewContext))
    }
    
    private let store = CNContactStore()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchQuery)
                
                Text("We will notify you on each of your contacts' birthdays")
                    .font(.system(size: 14, weight: .regular))
                
                ScrollView {
                    VStack {
                        ForEach(contacts.filter({ "\($0.name ?? "")".contains(searchQuery) || searchQuery.isEmpty }), id: \.self) { contact in
                            NavigationLink(destination: ContactDetailView(contact: contact)) {
                                VStack(alignment: .leading, spacing: 8) { // Adjust the spacing between elements
                                    HStack{
                                        Text(contact.name ?? "")
                                            .font(.system(size: 20, weight: .bold)) // Update the font weight
                                            .foregroundColor(.primary) // Use the default text color
                                        
                                        Spacer()
                                        
                                        NavigationLink(destination: ContactDetailView(contact: contact)) {
                                            Text("Edit")
                                                .font(.system(size: 14, weight: .regular)) // Update the font
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Color.robinhoodGreen) // Use Robinhood green color
                                                .cornerRadius(8)
                                        }
                                        .padding(.top, 10) // Add padding to push the button down
                                    }
                                    .padding(.bottom, 1)
                                    
                                    HStack {
                                        Image(systemName: "calendar").foregroundColor(contact.birthday != nil ? Color.robinhoodGreen : .customRed)
                                        Text(contact.birthday != nil ? "Birthday: \(dateFormatter.string(from: contact.birthday!))" : "Missing birthday date")
                                            .font(.system(size: 16, weight: .regular)) // Update the font
 
                                    }
                                    .padding(.bottom, 1)
                                    
                                    HStack {
                                        Image(systemName: "bell").foregroundColor(contact.message != nil && contact.message != "" ? Color.robinhoodGreen : .customRed)
                                        Text(contact.message != nil && contact.message != "" ? "Message: \(contact.message ?? "")" : "Missing birthday message")
                                            .font(.system(size: 16, weight: .regular)) // Update the font
                                    }
                                    .padding(.bottom, 1)
                                    
                                    Divider().padding(.top, 4)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white) // Use a white background
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 5)
                        }
                    }
                }
                .padding(.horizontal)
                .navigationTitle("Reminders")
                .onAppear(perform: loadContacts)
            }
        }
        .colorScheme(.light)
    }
    
    private func loadContacts() {
        contactManager.loadContactsFromAddressBook()
    }
}
