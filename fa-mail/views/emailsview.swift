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
    /// Show the Sent folder instead of the inbox
    var showsSent = false
    /// IMAP folder this list shows ("INBOX", or the server's sent folder)
    private(set) var folder = "INBOX"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Opaque nav bar + large title + pull-to-refresh: let the table sit under the bar,
        // otherwise iOS loses the large title after a refresh
        extendedLayoutIncludesOpaqueBars = true
        
        // Fetch the email count when the view loads
        if imapSession != nil {
          resolveFolder { [weak self] in
            guard let self = self else { return }
            self.getNumberOfEmailsForFolder(withFolder: self.folder, session: self.imapSession) { emailCount in
                print("\(self.folder) email count: \(emailCount)")
                
                
              DispatchQueue.main.async {
                // Set the large title display mode (collapses when sideways)
                self.navigationItem.largeTitleDisplayMode = .automatic

                // Purple nav bar with white cursive title
                FATheme.apply(to: self.navigationController?.navigationBar)
                
                // Enable large titles
                self.navigationController?.navigationBar.prefersLargeTitles = true
                self.title = self.showsSent ? "Sent" : "FA-Mail" // Set the title to show in the large title
              }
                

                
                self.totalInboxEmails = emailCount
                
                // Proceed with any logic that depends on the email count
                self.fetchEmails()
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            }
          }
            
            let refreshControl = UIRefreshControl()
            self.refreshControl = refreshControl  // Set the inherited property
            refreshControl.addTarget(self, action: #selector(refreshInbox), for: .valueChanged)
            addNewMessageButton()
            if !showsSent { addSentButton() }
            
            // Hold down on a message to start selecting several
            tableView.allowsMultipleSelectionDuringEditing = true
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            tableView.addGestureRecognizer(longPress)
        }
    }
    
    /// Works out which IMAP folder to load, then calls completion
    private func resolveFolder(_ completion: @escaping () -> Void) {
        guard showsSent else { completion(); return }
        EmailViewController.resolveSentFolder(session: imapSession) { [weak self] name in
            self?.folder = name
            completion()
        }
    }
    
    private static var cachedSentFolder: String?
    
    /// Finds the server's sent-mail folder (creating "Sent" if there is none)
    static func resolveSentFolder(session: MCOIMAPSession, completion: @escaping (String) -> Void) {
        if let cached = cachedSentFolder { completion(cached); return }
        session.fetchAllFoldersOperation()?.start { error, folders in
            let all = (folders as? [MCOIMAPFolder]) ?? []
            let found = all.first(where: { $0.flags.contains(.sentMail) })?.path
                ?? all.first(where: { ["Sent", "Sent Messages", "Sent Items", "INBOX.Sent"].contains($0.path) })?.path
            if let found = found {
                cachedSentFolder = found
                completion(found)
            } else {
                // No sent folder on the server yet, so create one
                session.createFolderOperation("Sent")?.start { _ in
                    cachedSentFolder = "Sent"
                    completion("Sent")
                }
            }
        }
    }
    
    func addSentButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "paperplane"),
            style: .plain, target: self, action: #selector(showSentFolder))
        navigationItem.leftBarButtonItem?.tintColor = .white
    }
    
    @objc func showSentFolder() {
        let sentVC = EmailViewController()
        sentVC.showsSent = true
        sentVC.imapSession = imapSession
        sentVC.smtpSession = smtpSession
        navigationController?.pushViewController(sentVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return showsSent ? "Sent" : "Inbox"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emails.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EmailCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "EmailCell")
        let email = emails[indexPath.row]
        cell.textLabel?.text = email.header.subject ?? "No Subject"
        if showsSent {
            // Sent mail: show who it went to
            let to = (email.header.to as? [MCOAddress])?.compactMap { $0.mailbox }.joined(separator: ", ") ?? ""
            cell.detailTextLabel?.text = "To: \(to)"
        } else {
            cell.detailTextLabel?.text = email.header.sender.displayName
        }
        // Unread mail gets a red check and a bold subject
        let unread = !showsSent && !email.flags.contains(.seen)
        cell.imageView?.image = UIImage(systemName: "checkmark.circle.fill")
        cell.imageView?.tintColor = unread ? .systemRed : .clear
        cell.textLabel?.font = unread ? .boldSystemFont(ofSize: 17) : .systemFont(ofSize: 17)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // In selection mode a tap just checks the row
        if tableView.isEditing {
            updateSelectionButtons()
            return
        }
        let email = emails[indexPath.row]
        if !showsSent && !email.flags.contains(.seen) {
            markAsRead(email, at: indexPath)
        }
        
        // Initialize the EmailDetailViewController and pass the selected email and fetch method
        let detailViewController = EmailDetailViewController()
        detailViewController.email = email
        detailViewController.smtpSession = smtpSession
        detailViewController.username = imapSession.username
        detailViewController.imapSession = imapSession
        
        // adding fetch and delete closures
        detailViewController.fetchContentClosure = { [weak self] completion in
            self?.useImapFetchContent(uidToFetch: email.uid, completion: completion)
        }
        
        detailViewController.deleteEmailClosure = { [weak self] emailToDelete, completion in
            self?.deleteEmail(email: emailToDelete, completion: completion)
        }
        
        // TODO pass smtp session to deailview controller
        
        // Show in the right column when split, otherwise push
        if let split = splitViewController {
            split.setViewController(UINavigationController(rootViewController: detailViewController), for: .secondary)
            split.show(.secondary)
        } else {
            navigationController?.pushViewController(detailViewController, animated: true)
        }
    }
    
    @objc func refreshInbox() {
        print("Refreshing inbox...")
        // The badge is now synced to the unread count in fetchEmails()
        
        // Fetch the email count and reload
        getNumberOfEmailsForFolder(withFolder: folder, session: self.imapSession) { emailCount in
            self.totalInboxEmails = emailCount
            self.fetchEmails()
        }
    }
    
    @objc func addNewMessage() {
        let newMessageController = NewEmailViewController()
        newMessageController.smtpSession = smtpSession
        newMessageController.username = imapSession.username
        newMessageController.imapSession = imapSession
        navigationController?.pushViewController(newMessageController, animated: true)
    }
    
    @objc func appDidBecomeActive() {
        print("App became active - refreshing inbox")
        refreshInbox()
    }

    
    func addNewMessageButton() {
        // Compose button in the nav bar so it stays put when scrolling or rotating
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain, target: self, action: #selector(addNewMessage))
        navigationItem.rightBarButtonItem?.tintColor = .white
    }
    
    func fetchEmails() {
        if (self.totalInboxEmails > 0)
        {
            let fetchOperation = imapSession.fetchMessagesByNumberOperation(withFolder: folder, requestKind: [.headers, .flags], numbers: MCOIndexSet(range: MCORange(location: 1, length: UInt64(self.totalInboxEmails - 1))))
            
            fetchOperation?.start { [weak self] error, messages, vanishedMessages in
                
                if let error = error {
                    print("Error fetching messages: \(error)")
                    self?.refreshControl?.endRefreshing()
                    return
                }
                guard let messages = messages as? [MCOIMAPMessage] else {
                    self?.refreshControl?.endRefreshing()
                    return
                }
                self?.emails = messages
                // Badge = number of unread emails in the Inbox
                if self?.showsSent == false {
                    let unread = messages.filter { !$0.flags.contains(.seen) }.count
                    APNManager.shared.setAlertCount(unread)
                }
                // Learn addresses for recipient suggestions in New Email
                for message in messages {
                    let header = message.header
                    let people = [header?.from] + ((header?.to as? [MCOAddress]) ?? []) + ((header?.cc as? [MCOAddress]) ?? [])
                    AddressBook.shared.record(people)
                }
                self?.tableView.reloadData()
                self?.refreshControl?.endRefreshing()
                self?.navigationController?.navigationBar.sizeToFit()  // brings the large title back
            }
        }
        else {
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
                self.showNoEmailsAlert()
            }
        }
    }
    
    // Show an alert when there are no emails
    func showNoEmailsAlert() {
        let alert = UIAlertController(title: "No Emails", message: showsSent ? "You have no sent emails yet." : "There are no emails in your inbox.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func useImapFetchContent(uidToFetch uid: UInt32, completion: @escaping (String) -> Void) {
        let operation = imapSession.fetchParsedMessageOperation(withFolder: folder, uid: uid)
        
        operation?.start { (error, messageParser) in
            guard error == nil, let messageParser = messageParser else {
                completion("Error fetching body")
                return
            }
            
            // Get the plain text body
//            let body = messageParser.plainTextBodyRenderingAndStripWhitespace(false)
//            let attachments = messageParser.attachments()
            let bodyHtml = messageParser.htmlBodyRendering()
            
            // Return the body via the completion handler
            completion(bodyHtml ?? "No body content")
        }
    }
    
    func deleteEmail(email: MCOIMAPMessage, completion: @escaping (Bool) -> Void) {
        let folder = self.folder
        
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
}

// MARK: - Multi-select delete
extension EmailViewController {
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing { updateSelectionButtons() }
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, !tableView.isEditing,
              let indexPath = tableView.indexPathForRow(at: gesture.location(in: tableView)) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        setSelecting(true)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        updateSelectionButtons()
    }
    
    func setSelecting(_ on: Bool) {
        tableView.setEditing(on, animated: true)
        refreshControl?.isEnabled = !on
        if on {
            let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelSelecting))
            cancel.tintColor = .white
            navigationItem.leftBarButtonItem = cancel
            updateSelectionButtons()
        } else {
            addNewMessageButton()
            if showsSent { navigationItem.leftBarButtonItem = nil } else { addSentButton() }
        }
    }
    
    @objc func cancelSelecting() {
        setSelecting(false)
    }
    
    func updateSelectionButtons() {
        let count = tableView.indexPathsForSelectedRows?.count ?? 0
        let delete = UIBarButtonItem(title: count > 0 ? "Delete (\(count))" : "Delete",
                                     style: .done, target: self, action: #selector(confirmDeleteSelected))
        delete.tintColor = .white
        delete.isEnabled = count > 0
        navigationItem.rightBarButtonItem = delete
    }
    
    @objc func confirmDeleteSelected() {
        let count = tableView.indexPathsForSelectedRows?.count ?? 0
        guard count > 0 else { return }
        let alert = UIAlertController(title: "Delete Confirm",
                                      message: "Delete \(count) email\(count == 1 ? "" : "s")?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteSelectedEmails()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    /// Flags every selected email as deleted in one call, then expunges once
    func deleteSelectedEmails() {
        let rows = (tableView.indexPathsForSelectedRows ?? []).map { $0.row }.sorted(by: >)
        guard !rows.isEmpty else { return }
        let uids = MCOIndexSet()
        rows.forEach { uids.add(UInt64(emails[$0].uid)) }
        let folder = self.folder
        
        let showFailure = { [weak self] (error: Error) in
            print("Bulk delete failed:", error.localizedDescription)
            let alert = UIAlertController(title: "Failure", message: "mail not deleted!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
        
        imapSession.storeFlagsOperation(withFolder: folder, uids: uids, kind: .add, flags: .deleted)?.start { [weak self] error in
            guard let self = self else { return }
            if let error = error { showFailure(error); return }
            self.imapSession.expungeOperation(folder)?.start { [weak self] error in
                guard let self = self else { return }
                if let error = error { showFailure(error); return }
                rows.forEach { self.emails.remove(at: $0) }
                self.totalInboxEmails = max(0, self.totalInboxEmails - rows.count)
                self.tableView.deleteRows(at: rows.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.setSelecting(false)
            }
        }
    }
}

extension EmailViewController: UISplitViewControllerDelegate {
    // In portrait, open on the inbox instead of the blank detail page
    func splitViewController(_ svc: UISplitViewController,
                             topColumnForCollapsingToProposedTopColumn proposed: UISplitViewController.Column) -> UISplitViewController.Column {
        return .primary
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

// MARK: - Read / unread
extension EmailViewController {
    /// Flag the email as read on the server, drop the red check, and take one off the badge.
    func markAsRead(_ email: MCOIMAPMessage, at indexPath: IndexPath) {
        email.flags.insert(.seen)
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        APNManager.shared.decrementAlertCount()
        
        let op = imapSession.storeFlagsOperation(withFolder: folder, uids: MCOIndexSet(index: UInt64(email.uid)), kind: .add, flags: .seen)
        op?.start { error in
            if let error = error { print("Couldn't mark as read:", error.localizedDescription) }
        }
    }
}
