//
//  newemailview.swift
//  fa-mail
//
//  Created by Sebastian Campos on 3/5/25.
//

import SwiftUI

class NewEmailViewController: UIViewController {
    
    var email: MCOIMAPMessage?
    var username: String!
    var smtpSession: MCOSMTPSession!
    var imapSession: MCOIMAPSession?
    var fetchContentClosure: ((@escaping (String) -> Void) -> Void)?
    var deleteEmailClosure: ((MCOIMAPMessage, @escaping (Bool) -> Void) -> Void)?
    var replyToEmail: String?
    var replyContent: String?
    var replyToSubject: String?
    private let recipientEmail = UITextField()
    private let subjectLabel = UITextField()
    private let bodyTextView = UITextView()
    private let suggestionsTable = UITableView(frame: .zero, style: .plain)
    private var suggestions: [AddressBook.Entry] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "New Email"
        setupViews()
        addSendButton()
    }
    
    func setupViews() {
        
        // Set up the views to display email details
        recipientEmail.translatesAutoresizingMaskIntoConstraints = false
        recipientEmail.placeholder = "Recipient"
        if replyToEmail != nil {
            recipientEmail.text = replyToEmail
        }
        
        recipientEmail.autocapitalizationType = .none
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        subjectLabel.placeholder = "Subject"
        if replyToSubject != nil {
            if replyToSubject!.contains("Re: "){
                subjectLabel.text = replyToSubject
            }
            else {
                subjectLabel.text = "Re: \(replyToSubject!)"
            }
        }
        
        
        bodyTextView.translatesAutoresizingMaskIntoConstraints = false
        bodyTextView.font = UIFont.systemFont(ofSize: 14)
        if replyContent != nil {
            bodyTextView.text = replyContent
        }
        
        view.addSubview(recipientEmail)
        view.addSubview(subjectLabel)
        view.addSubview(bodyTextView)
        
        // Recipient suggestions, floating under the To field
        recipientEmail.keyboardType = .emailAddress
        recipientEmail.autocorrectionType = .no
        recipientEmail.addTarget(self, action: #selector(recipientChanged), for: .editingChanged)
        recipientEmail.addTarget(self, action: #selector(hideSuggestions), for: .editingDidEnd)
        suggestionsTable.translatesAutoresizingMaskIntoConstraints = false
        suggestionsTable.dataSource = self
        suggestionsTable.delegate = self
        suggestionsTable.isHidden = true
        suggestionsTable.layer.cornerRadius = 10
        suggestionsTable.layer.borderWidth = 1
        suggestionsTable.layer.borderColor = UIColor.faPurple.withAlphaComponent(0.4).cgColor
        suggestionsTable.backgroundColor = .secondarySystemBackground
        suggestionsTable.rowHeight = 52
        view.addSubview(suggestionsTable)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            recipientEmail.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            recipientEmail.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            recipientEmail.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subjectLabel.topAnchor.constraint(equalTo: recipientEmail.bottomAnchor, constant: 20),
            subjectLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subjectLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            bodyTextView.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 20),
            bodyTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bodyTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bodyTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            suggestionsTable.topAnchor.constraint(equalTo: recipientEmail.bottomAnchor, constant: 6),
            suggestionsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            suggestionsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            suggestionsTable.heightAnchor.constraint(equalToConstant: 52 * 4)
        ])
    }
    
    func addSendButton() {
        let sendButton = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(sendEmail))
        sendButton.tintColor = .green
        navigationItem.rightBarButtonItem = sendButton
    }
    
    @objc func sendEmail() {
        guard let recipient = recipientEmail.text, !recipient.isEmpty,
              let subject = subjectLabel.text, !subject.isEmpty,
              let body = bodyTextView.text, !body.isEmpty else {
            let alert = UIAlertController(title: "Missing Information", message: "Please fill all fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let alert = UIAlertController(title: "Send Confirm", message: "Send email?", preferredStyle: .alert)
        
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {[weak self] _ in
            
            guard let self = self else { return }
            // Prepare the message builder
            let builder = MCOMessageBuilder()
            builder.header.to = [MCOAddress(displayName: nil, mailbox: recipient)!]
            builder.header.from = MCOAddress(displayName: username, mailbox: username + "@mail.friendlyautomations.com")
            builder.header.subject = subject
            builder.htmlBody = body.replacingOccurrences(of: "\n", with: "<br>")
            
            // Create the RFC822 data for the message
            let rfc822Data = builder.data()
            
            // Start the send operation
            let sendOperation = smtpSession.sendOperation(with: rfc822Data)
            
            // Perform the asynchronous send operation
            sendOperation?.start { (error) in
                if error != nil {
                    print("Sending Error: ", error?.localizedDescription)
                    let alert = UIAlertController(title: "Failure", message: "mail not sent!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    AddressBook.shared.record([MCOAddress(displayName: nil, mailbox: recipient)])
                    // Save a copy to the server's Sent folder
                    if let imap = self.imapSession {
                        EmailViewController.resolveSentFolder(session: imap) { sentFolder in
                            imap.appendMessageOperation(withFolder: sentFolder, messageData: rfc822Data, flags: .seen)?.start { error, _ in
                                if let error = error { print("Couldn't save to Sent:", error.localizedDescription) }
                            }
                        }
                    }
                    let alert = UIAlertController(title: "Sent", message: "Mail sent", preferredStyle: .alert)
                     alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                         // Navigate back after sending
                         self.navigationController?.popViewController(animated: true)
                     }))
                     self.present(alert, animated: true, completion: nil)

                }
            }
        }))

        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))

        // Present the alert
        self.present(alert, animated: true, completion: nil)
        
    }
    
}


// MARK: - Recipient suggestions
extension NewEmailViewController: UITableViewDataSource, UITableViewDelegate {
    @objc func recipientChanged() {
        suggestions = AddressBook.shared.suggestions(for: recipientEmail.text ?? "")
        suggestionsTable.isHidden = suggestions.isEmpty
        suggestionsTable.reloadData()
    }
    
    @objc func hideSuggestions() {
        suggestionsTable.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "suggestion")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "suggestion")
        let entry = suggestions[indexPath.row]
        cell.backgroundColor = .clear
        cell.textLabel?.text = entry.name ?? entry.email
        cell.detailTextLabel?.text = entry.name == nil ? nil : entry.email
        cell.detailTextLabel?.textColor = .secondaryLabel
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        recipientEmail.text = suggestions[indexPath.row].email
        hideSuggestions()
        subjectLabel.becomeFirstResponder()
    }
}

// MARK: - Local address book (built from mail you've received and sent)
final class AddressBook {
    static let shared = AddressBook()
    
    struct Entry: Codable {
        var email: String
        var name: String?
        var count: Int
    }
    
    private let key = "fa.addressBook"
    private var entries: [String: Entry] = [:]
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([String: Entry].self, from: data) {
            entries = saved
        }
    }
    
    /// Remember addresses seen in mail. Call with senders/recipients as headers load.
    func record(_ addresses: [MCOAddress?]) {
        var changed = false
        for case let address? in addresses {
            guard let mailbox = address.mailbox?.lowercased(), mailbox.contains("@") else { continue }
            var entry = entries[mailbox] ?? Entry(email: mailbox, name: nil, count: 0)
            entry.count += 1
            if let name = address.displayName?.trimmingCharacters(in: .whitespaces), !name.isEmpty, name.lowercased() != mailbox {
                entry.name = name
            }
            entries[mailbox] = entry
            changed = true
        }
        if changed, let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    /// Best matches for what's typed, most-used first.
    func suggestions(for text: String, limit: Int = 4) -> [Entry] {
        let query = text.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return [] }
        return entries.values
            .filter { $0.email.contains(query) || ($0.name?.lowercased().contains(query) ?? false) }
            .filter { $0.email != query }
            .sorted { a, b in
                let aPrefix = a.email.hasPrefix(query) || (a.name?.lowercased().hasPrefix(query) ?? false)
                let bPrefix = b.email.hasPrefix(query) || (b.name?.lowercased().hasPrefix(query) ?? false)
                if aPrefix != bPrefix { return aPrefix }
                return a.count > b.count
            }
            .prefix(limit)
            .map { $0 }
    }
}
