import SwiftUI
import MessageUI

struct MessageComposer: UIViewControllerRepresentable {
    var recipientNumber: String = ""
    var messageBody: String = ""
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        @Binding var presented: Bool
        init(presented: Binding<Bool>) {
            _presented = presented
        }
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
            self.presented = false
        }
    }

    @Binding var presented: Bool

    func makeCoordinator() -> Coordinator {
        return Coordinator(presented: $presented)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MessageComposer>) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.body = messageBody
        controller.recipients = [recipientNumber]
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController,
                                context: UIViewControllerRepresentableContext<MessageComposer>) {

    }
}
