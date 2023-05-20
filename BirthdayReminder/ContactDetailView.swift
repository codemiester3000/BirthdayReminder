import SwiftUI

struct ContactDetailView: View {
    @ObservedObject var contact: Contact
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var isShowingEditView = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading) {
            Group {
                Text(contact.name ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if let birthday = contact.birthday {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                        Text(dateFormatter.string(from: birthday))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical)
                } else {
                    Button(action: {
                        self.isShowingEditView = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                            Text("Add Birthday")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical)
                }
                
                HStack {
                    Image(systemName: "message")
                        .foregroundColor(.gray)
                    Text(contact.message ?? "")
                        .foregroundColor(.gray)
                }
                .padding(.vertical)
            }
            
            Spacer()
            
            Button(action: {
                self.isShowingEditView = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Message and Birthday")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.bottom)
            .sheet(isPresented: $isShowingEditView) {
                EditMessageView(
                    isPresented: $isShowingEditView,
                    message: Binding<String>(
                        get: { self.contact.message ?? "" },
                        set: {
                            self.contact.message = $0
                        }
                    ),
                    birthday: Binding<Date?>(
                        get: { self.contact.birthday },
                        set: {
                            self.contact.birthday = $0
                        }
                    )
                )
                .onDisappear {
                    saveContext()
                }
            }
        }
        .padding()
        .navigationTitle("Contact")
    }
    
    func saveContext() {
        do {
            try self.viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

