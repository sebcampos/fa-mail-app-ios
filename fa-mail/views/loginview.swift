//
//  loginview.swift
//  fa-mail
//
//  Created by Sebastian Campos on 3/5/25.
//

import SwiftUI

class LoginViewController: UIViewController {
    
    // UI elements
    let usernameTextField = UITextField()
    let passwordTextField = UITextField()
    let loginButton = UIButton()
    let loadingIndicator = UIActivityIndicatorView(style: .large)


    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Set the large title display mode
        self.navigationItem.largeTitleDisplayMode = .always
        
        

        // Customize navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white, // Set title color
            .font: UIFont.boldSystemFont(ofSize: 32) ,// Set font size
        ]
        
        appearance.backgroundColor = .systemIndigo
        
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        // Enable large titles
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.title = "FA-Mail" // Set the title to show in the large title
        
        setupViews()
    }
    
    func setupViews() {
        // View setup
        
        // Username Text Field
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        usernameTextField.placeholder = "Username"
        usernameTextField.borderStyle = .roundedRect
        usernameTextField.autocapitalizationType = .none
        view.addSubview(usernameTextField)
        
        // Password Text Field
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.placeholder = "Password"
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true
        view.addSubview(passwordTextField)
        
        // Login Button
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.setTitle("Login", for: .normal)
        loginButton.backgroundColor = .systemIndigo
        loginButton.layer.cornerRadius = 5
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        view.addSubview(loginButton)
        
        // Loading Indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            usernameTextField.widthAnchor.constraint(equalToConstant: 300),
            
            passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            passwordTextField.widthAnchor.constraint(equalToConstant: 300),
            
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30),
            loginButton.widthAnchor.constraint(equalToConstant: 200),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20)
        ])
    }
    
    @objc func loginButtonTapped() {
        // Get entered username and password
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // Show an alert if username or password is empty
            let alert = UIAlertController(title: "Error", message: "Please enter both username and password.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        // Disable the input fields and show the loading spinner
        usernameTextField.isEnabled = false
        passwordTextField.isEnabled = false
        loginButton.isEnabled = false
        loadingIndicator.startAnimating()  // Show the loading spinner
        
        
        // Create the IMAP session with entered credentials
        let imapSession = MCOIMAPSession()
        let smtpSession = MCOSMTPSession()
        imapSession.hostname = "friendlyautomations.com"
        imapSession.username = username
        imapSession.password = password
        imapSession.port = 993
        imapSession.isVoIPEnabled = false
        imapSession.connectionType = .TLS
        
        
        smtpSession.hostname = "friendlyautomations.com"
        smtpSession.port = 587  // Use 587 for TLS, 465 for SSL, or 25 (non-secure) if needed
        smtpSession.username = username
        smtpSession.password = password
        smtpSession.connectionType = .startTLS
        
        

        // Validate credentials by fetching email count from inbox
        EmailViewController().getNumberOfEmailsForFolder(withFolder: "INBOX", session: imapSession) { [weak self] emailCount in
            if emailCount != -1 {
                // Credentials are correct, move to the email screen
                DispatchQueue.main.async {
                    self?.navigateToEmailScreen(imapSession: imapSession, smtpSession: smtpSession)
                }
            } else {
                // Invalid credentials
                DispatchQueue.main.async {
                    // Hide the loading spinner and enable input fields
                    self?.loadingIndicator.stopAnimating()
                    self?.usernameTextField.isEnabled = true
                    self?.passwordTextField.isEnabled = true
                    self?.loginButton.isEnabled = true
                    self?.usernameTextField.text = ""
                    self?.passwordTextField.text = ""
                    let alert = UIAlertController(title: "Login Failed", message: "Invalid username or password. Please try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func navigateToEmailScreen(imapSession: MCOIMAPSession, smtpSession: MCOSMTPSession) {
        // Initialize the EmailViewController and set the imapSession
        let emailVC = EmailViewController()
        emailVC.imapSession = imapSession
        emailVC.smtpSession = smtpSession
        
        
        if let navigationController = self.navigationController {
            // Set the EmailViewController as the root view controller
            navigationController.setViewControllers([emailVC], animated: true)
        }
    }
}
