import SwiftUI

// Extension on View to dismiss the keyboard
extension View {
    func endEditing(_ force: Bool) {
        UIApplication.shared.windows
            .filter{$0.isKeyWindow}
            .first?
            .endEditing(force)
    }
}

struct EditMessageView: View {
    @Binding var isPresented: Bool
    @Binding var message: String
    @Binding var birthday: Date?

    // Create a local variable that creates a binding to the non-optional date.
    private var nonOptionalDate: Binding<Date> {
        Binding<Date>(
            get: { self.birthday ?? Date() },
            set: { self.birthday = $0 }
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Birthday")) {
                    DatePicker("Select Date", selection: nonOptionalDate, displayedComponents: .date)
                }
                Section(header: Text("Message")) {
                    TextEditor(text: $message)
                        .foregroundColor(.primary)
                        .frame(minHeight: 100)
                }
            }
            .onTapGesture {
                endEditing(true) // This will dismiss the keyboard when you tap outside the TextEditor
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.isPresented = false
                    }) {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.isPresented = false
                    }) {
                        Text("Save")
                    }
                }
            }
        }
    }
}
