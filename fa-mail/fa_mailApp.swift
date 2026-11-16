//
//  fa_mailApp.swift
//  fa-mail
//
//  Created by Sebastian Campos on 12/31/24.
//

import SwiftUI

// MARK: - App theme
extension UIColor {
    /// Purple from the friendlyautomations.com header
    static let faPurple = UIColor(red: 127/255, green: 58/255, blue: 217/255, alpha: 1)
}

enum FATheme {
    static func cursive(_ size: CGFloat) -> UIFont {
        // FaktSlabStencilPro-Medium, savoyeLetPlain, SnellRoundHand, ChalkDuster
        UIFont(name: "FaktSlabStencilPro-Medium", size: size) ?? .boldSystemFont(ofSize: size)
    }

    /// Purple nav bar with white cursive titles
    static func navBarAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .faPurple
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: cursive(24)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white, .font: cursive(40)]
        return appearance
    }

    static func apply(to navBar: UINavigationBar?) {
        let appearance = navBarAppearance()
        navBar?.standardAppearance = appearance
        navBar?.scrollEdgeAppearance = appearance
        navBar?.compactAppearance = appearance
        navBar?.tintColor = .white
    }

    /// Default for every nav bar in the app (Email Detail, New Email, split view columns)
    static func applyGlobally() {
        let appearance = navBarAppearance()
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.tintColor = .white
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FATheme.applyGlobally()
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
            LoginViewControllerWrapper()
                .ignoresSafeArea()
        }
    }
}
