//
//  emailsview.swift
//  fa-mail
//
//  Created by Sebastian Campos on 3/5/25.
//

import SwiftUI

class EmailViewController: UITableViewController {
    var emails: [MCOIMAPMessage] = []
    var imapSession: MCOIMAPSession!
    var smtpSession: MCOSMTPSession!
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
                
                appearance.backgroundColor = UIColor.systemIndigo
                
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
            addNewMessageButton()
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
    
    func addNewMessageButton() {
        let startNewMessage = UIBarButtonItem(title: "New", style: .plain, target: self, action: #selector(addNewMessage))
        startNewMessage.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = startNewMessage
    }
    
    @objc func addNewMessage() {
        let newMessageController = NewEmailViewController()
        newMessageController.smtpSession = smtpSession
        navigationController?.pushViewController(newMessageController, animated: true)
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
