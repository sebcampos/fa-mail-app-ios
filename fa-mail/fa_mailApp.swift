//
//  fa_mailApp.swift
//  fa-mail
//
//  Created by Sebastian Campos on 12/31/24.
//

import SwiftUI


class LoginViewController: UIViewController {
    
    // UI elements
    let usernameTextField = UITextField()
    let passwordTextField = UITextField()
    let loginButton = UIButton()


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
        
        appearance.backgroundColor = UIColor.systemPurple
        
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
        loginButton.backgroundColor = .systemPurple
        loginButton.layer.cornerRadius = 5
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        view.addSubview(loginButton)
        
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
            loginButton.heightAnchor.constraint(equalToConstant: 50)
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
        
        // Create the IMAP session with entered credentials
        let imapSession = MCOIMAPSession()
        imapSession.hostname = "friendlyautomations.com"
        imapSession.username = username
        imapSession.password = password
        imapSession.port = 993
        imapSession.isVoIPEnabled = false
        imapSession.connectionType = .TLS
        
        

        // Validate credentials by fetching email count from inbox
        EmailViewController().getNumberOfEmailsForFolder(withFolder: "INBOX", session: imapSession) { [weak self] emailCount in
            if emailCount != -1 {
                // Credentials are correct, move to the email screen
                DispatchQueue.main.async {
                    self?.navigateToEmailScreen(imapSession: imapSession)
                }
            } else {
                // Invalid credentials
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Login Failed", message: "Invalid username or password. Please try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func navigateToEmailScreen(imapSession: MCOIMAPSession) {
        // Initialize the EmailViewController and set the imapSession
        let emailVC = EmailViewController()
        emailVC.imapSession = imapSession
        
        
        if let navigationController = self.navigationController {
            // Set the EmailViewController as the root view controller
            navigationController.setViewControllers([emailVC], animated: true)
        }
    }
}

class EmailDetailViewController: UIViewController {
    
    var email: MCOIMAPMessage?
    var fetchContentClosure: ((@escaping (String) -> Void) -> Void)?
    var deleteEmailClosure: ((MCOIMAPMessage, @escaping (Bool) -> Void) -> Void)?
    
    private let subjectLabel = UILabel()
    private let fromLabel = UILabel()
    private let dateLabel = UILabel()
    private let bodyTextView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Email Detail"
        setupViews()
        displayEmailDetails()
        addDeleteButton()
    }

    func setupViews() {
        // Set up the views to display email details
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        fromLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyTextView.translatesAutoresizingMaskIntoConstraints = false
        
        bodyTextView.isEditable = false
        bodyTextView.font = UIFont.systemFont(ofSize: 14)
        
        view.addSubview(subjectLabel)
        view.addSubview(fromLabel)
        view.addSubview(dateLabel)
        view.addSubview(bodyTextView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            subjectLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            subjectLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subjectLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            fromLabel.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 10),
            fromLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fromLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            dateLabel.topAnchor.constraint(equalTo: fromLabel.bottomAnchor, constant: 10),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            bodyTextView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
            bodyTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bodyTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bodyTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    func displayEmailDetails() {
        guard let email = email else { return }
        
        subjectLabel.text = "Subject: \(email.header.subject ?? "No Subject")"
        fromLabel.text = "From: \(email.header.sender.displayName ?? "Unknown Sender")"
        dateLabel.text = "Date: \(email.header.date?.description ?? "Unknown Date")"
        
        // Fetch the body using the passed closure
        fetchContentClosure? { [weak self] body in
            DispatchQueue.main.async {
                self?.bodyTextView.text = body
            }
        }
    }
    
    
    func addDeleteButton() {
        let deleteButton = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteEmail))
        deleteButton.tintColor = .red
        navigationItem.rightBarButtonItem = deleteButton
    }

    @objc func deleteEmail() {
        guard let email = email else { return }

        // Call the delete closure to delete the email
        deleteEmailClosure?(email) { [weak self] success in
            if success {
                // If deletion is successful, pop the current view controller
                self?.navigationController?.popViewController(animated: true)
            } else {
                // Handle the error or show an alert to the user
                print("Failed to delete email.")
            }
        }
    }
    
}

class EmailViewController: UITableViewController {
    var emails: [MCOIMAPMessage] = []
    var imapSession: MCOIMAPSession!
    var totalInboxEmails: Int = 0
    
    
    func getNumberOfEmailsForFolder(withFolder: String,  session: MCOIMAPSession, completion: @escaping (Int) -> Void) {
        let folderInfoOperation = session.folderInfoOperation(withFolder)
        
        folderInfoOperation?.start { error, folderInfo in
            if let error = error {
                print("Error fetching folder info: \(error)")
                completion(-1) // Return -1 in case of error
                return
            }
            
            guard let folderInfo = folderInfo else {
                print("No folder info found.")
                completion(-1) // Return -1 if no folder info
                return
            }
            
            let emailCount = Int(folderInfo.messageCount)
            completion(emailCount) // Return the actual email count
        }

    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Fetch the email count when the view loads
        if imapSession != nil {
            getNumberOfEmailsForFolder(withFolder: "INBOX", session: imapSession) { emailCount in
                print("Inbox email count: \(emailCount)")
                
                
                // Set the large title display mode
                self.navigationItem.largeTitleDisplayMode = .always

                // Customize navigation bar appearance
                let appearance = UINavigationBarAppearance()
                appearance.largeTitleTextAttributes = [
                    .foregroundColor: UIColor.white, // Set title color
                    .font: UIFont.boldSystemFont(ofSize: 32) ,// Set font size
                ]
                
                appearance.backgroundColor = UIColor.systemPurple
                
                self.navigationController?.navigationBar.standardAppearance = appearance
                self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
                
                // Enable large titles
                self.navigationController?.navigationBar.prefersLargeTitles = true
                self.title = "FA-Mail" // Set the title to show in the large title
                

                
                self.totalInboxEmails = emailCount
                
                // Proceed with any logic that depends on the email count
                self.fetchEmails()
            }
            
            let refreshControl = UIRefreshControl()
            self.refreshControl = refreshControl  // Set the inherited property
            refreshControl.addTarget(self, action: #selector(refreshInbox), for: .valueChanged)
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EmailCell")
        }
    }

    func fetchEmails() {
        let folder = "INBOX"
        if (self.totalInboxEmails != 0)
        {
            let fetchOperation = imapSession.fetchMessagesByNumberOperation(withFolder: folder, requestKind: .headers, numbers: MCOIndexSet(range: MCORange(location: 1, length: UInt64(self.totalInboxEmails - 1))))
            
            fetchOperation?.start { [weak self] error, messages, vanishedMessages in
                
                if let error = error {
                    print("Error fetching messages: \(error)")
                    return
                }
                guard let messages = messages as? [MCOIMAPMessage] else {
                    return
                }
                self?.emails = messages
                self?.tableView.reloadData()
            }
        }
        else {
            self.showNoEmailsAlert()
        }
    }
    
    // Show an alert when there are no emails
    func showNoEmailsAlert() {
        let alert = UIAlertController(title: "No Emails", message: "There are no emails in your inbox.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func useImapFetchContent(uidToFetch uid: UInt32, completion: @escaping (String) -> Void) {
        let operation = imapSession.fetchParsedMessageOperation(withFolder: "INBOX", uid: uid)
        
        operation?.start { (error, messageParser) in
            guard error == nil, let messageParser = messageParser else {
                completion("Error fetching body")
                return
            }
            
            // Get the plain text body
            let body = messageParser.plainTextBodyRenderingAndStripWhitespace(false)
            
            
            // Return the body via the completion handler
            completion(body ?? "No body content")
        }
    }
    
    func deleteEmail(email: MCOIMAPMessage, completion: @escaping (Bool) -> Void) {
        let folder = "INBOX"
        
        // Step 1: Mark the email as deleted
        let storeFlagsOperation = imapSession.storeFlagsOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(email.uid)), kind: .add, flags: .deleted)
        
        storeFlagsOperation?.start { error in
            if let error = error {
                print("Error marking email for deletion: \(error)")
                return
            }

            // Step 2: Expunge the folder to permanently delete the email
            let expungeOperation = self.imapSession.expungeOperation(folder)
            expungeOperation?.start { expungeError in
                if let expungeError = expungeError {
                    print("Error expunging folder: \(expungeError)")
                    completion(false)
                } else {
                    print("Email deleted successfully")
                    // Optionally, remove the email from your `emails` array and reload the table
                    if let index = self.emails.firstIndex(of: email) {
                        self.emails.remove(at: index)
                        self.tableView.reloadData()
                    }
                    completion(true)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Inbox"
    }
    
    
    
    @objc func refreshInbox() {
        print("Refreshing inbox...")
        
        // Fetch the email count and reload
        getNumberOfEmailsForFolder(withFolder: "INBOX", session: self.imapSession) { emailCount in
            self.totalInboxEmails = emailCount
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()  // Always stop refreshing on the main thread
            }
            self.fetchEmails()  // Reload emails after refreshing
        }
    }
    
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emails.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EmailCell", for: indexPath)
        let email = emails[indexPath.row]
        cell.textLabel?.text = email.header.subject ?? "No Subject"
        cell.detailTextLabel?.text = email.header.sender.displayName
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let email = emails[indexPath.row]
        
        // Initialize the EmailDetailViewController and pass the selected email and fetch method
        let detailViewController = EmailDetailViewController()
        detailViewController.email = email
        
        // adding fetch and delete closures
        detailViewController.fetchContentClosure = { [weak self] completion in
            self?.useImapFetchContent(uidToFetch: email.uid, completion: completion)
        }
        
        detailViewController.deleteEmailClosure = { [weak self] emailToDelete, completion in
            self?.deleteEmail(email: emailToDelete, completion: completion)
        }
        
        // Push the detail view controller
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

struct EmailViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let emailVC = EmailViewController()
        let navigationController = UINavigationController(rootViewController: emailVC)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Any updates to the view controller can go here.
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
    var body: some Scene {
        WindowGroup {
            NavigationView { // Make sure the NavigationView is here
                LoginViewControllerWrapper()
            }
        }
    }
}
