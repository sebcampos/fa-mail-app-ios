//
//  fa_mailApp.swift
//  fa-mail
//
//  Created by Sebastian Campos on 12/31/24.
//

import SwiftUI

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
    var body: some Scene {
        WindowGroup {
            NavigationView { // Make sure the NavigationView is here
                LoginViewControllerWrapper()
            }
        }
    }
}
