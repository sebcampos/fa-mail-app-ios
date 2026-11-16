//
//  apnmanager.swift
//  fa-mail
//
//  Created by Sebastian Campos on 3/11/25.
//

import UIKit
import UserNotifications

class APNManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = APNManager()
    
    // Method to register for push notifications
    func registerForPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    // Register the device for remote notifications
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Push Notification permission denied: \(String(describing: error))")
            }
        }
    }
    
    
    
    // This method gets called when the APNs successfully assigns a device token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceToken = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(deviceToken, forKey: "deviceToken")
        
    }
    
    // Handle errors in registration
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for push notifications: \(error.localizedDescription)")
    }
    
    // Updated method to send device token with a specific email
    func sendDeviceTokenToServer() {
        let email = UserDefaults.standard.string(forKey: "userEmail")
        let tokenString = UserDefaults.standard.string(forKey: "deviceToken")
        let url = URL(string: "https://www.friendlyautomations.com/api/apn/device-token/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["email": email!, "token": tokenString!]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send device token: \(error.localizedDescription)")
                return
            }
            print("Device token successfully sent to server")
        }.resume()
    }
    
    func resetAlertCount() {
        let tokenString = UserDefaults.standard.string(forKey: "deviceToken") ?? ""
        let urlString = "https://www.friendlyautomations.com/api/apn/device-token?device_token=\(tokenString)&count=0"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        //request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        if let url = URL(string: urlString) {
            request.url = url
        } else {
            // Handle invalid URL
            print("Invalid URL")
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to update device token count: \(error.localizedDescription)")
                return
            }
            print("Device token successfully sent to server")
        }.resume()
        
    }
    
    /// Set the badge on the phone and the server's alert count to an exact number.
    /// The server adds 1 to this count each time it pushes a new email.
    func setAlertCount(_ count: Int) {
        let count = max(count, 0)
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error { print("Error setting badge: \(error.localizedDescription)") }
        }
        let tokenString = UserDefaults.standard.string(forKey: "deviceToken") ?? ""
        guard !tokenString.isEmpty,
              let url = URL(string: "https://www.friendlyautomations.com/api/apn/device-token?device_token=\(tokenString)&count=\(count)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error { print("Failed to update alert count: \(error.localizedDescription)") }
        }.resume()
    }
    
    /// Take one off the badge, e.g. when an unread email is opened.
    func decrementAlertCount() {
        DispatchQueue.main.async {
            self.setAlertCount(UIApplication.shared.applicationIconBadgeNumber - 1)
        }
    }
}
