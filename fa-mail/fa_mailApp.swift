//
//  fa_mailApp.swift
//  fa-mail
//
//  Created by Sebastian Campos on 12/31/24.
//

import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        APNManager.shared.registerForPushNotifications()
        return true
    }
    
    // Called when successfully registered for push notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        APNManager.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    // Called when push notification registration fails
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        APNManager.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    
}

struct LoginViewControllerWrapper: UIViewControllerRepresentable {
    
    // This method creates the view controller
    func makeUIViewController(context: Context) -> UINavigationController {
        let loginVC = LoginViewController() // Create an instance of LoginViewController
        
        // Create a UINavigationController with LoginViewController as the root
        let navigationController = UINavigationController(rootViewController: loginVC)
        
        return navigationController // Return the UINavigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // This can be used to update the view controller's state when SwiftUI updates the view.
    }
}


@main
struct fa_mailApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            NavigationView { // Make sure the NavigationView is here
                LoginViewControllerWrapper()
            }
        }
    }
}
