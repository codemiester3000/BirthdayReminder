// AppDelegate.swift

import UIKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        return true
    }
    
    // Handle receiving local notification while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge]) // execute the block with options you prefer
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // Get contact's details from the notification's user info
        if let phoneNumber = userInfo["phoneNumber"] as? String,
           let message = userInfo["message"] as? String {

            // Save phone number and message to UserDefaults so the app can access them when it becomes active
            UserDefaults.standard.set(phoneNumber, forKey: "phoneNumber")
            UserDefaults.standard.set(message, forKey: "message")
        }

        completionHandler()
    }
}
