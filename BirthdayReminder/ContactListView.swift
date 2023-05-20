import SwiftUI
import Contacts
import CoreData
import UIKit

extension Color {
    static let lightGreen = Color(red: 201/255, green: 255/255, blue: 191/255)
    static let darkBrown = Color(red: 101/255, green: 67/255, blue: 33/255)
    static let offWhite = Color(red: 225/255, green: 225/255, blue: 235/255)
}

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
                .padding(.top, 12)
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
                    .background(Color.lightGreen.opacity(0.2))
                ScrollView {
                    VStack {
                        ForEach(contacts.filter({ "\($0.name ?? "")".contains(searchQuery) || searchQuery.isEmpty }), id: \.self) { contact in
                            NavigationLink(destination: ContactDetailView(contact: contact)) {
                                VStack(alignment: .leading) {
                                    HStack{
                                        Text(contact.name ?? "")
                                            .font(Font.custom("Roboto-Bold", size: 20))
                                    }
                                    .padding(.bottom, 1)
                                        
                                    HStack {
                                        Image(systemName: "calendar")
                                        Text(contact.birthday != nil ? "Birthday: \(dateFormatter.string(from: contact.birthday!))" : "Missing birthday date")
                                            .font(Font.custom("Roboto-Regular", size: 16))
                                            .foregroundColor(contact.birthday != nil ? .blue : .red)
                                    }
                                    .padding(.bottom, 1)
                                        
                                    HStack {
                                        Image(systemName: "envelope")
                                        Text("Message: \(contact.message ?? "")")
                                            .font(Font.custom("Roboto-Regular", size: 16))
                                    }
                                    .padding(.bottom, 1)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.offWhite)
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 5)
                        }
                    }
                }
                .padding(.horizontal)
                .navigationTitle("Contacts")
                .background(Color.offWhite.opacity(0.2))
                .onAppear(perform: loadContacts)
            }
        }
        .background(Color.lightGreen.edgesIgnoringSafeArea(.all))
        .colorScheme(.light)
    }



    
    private func loadContacts() {
            contactManager.loadContactsFromAddressBook()
        }
}

