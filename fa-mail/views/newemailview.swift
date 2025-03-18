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
    var fetchContentClosure: ((@escaping (String) -> Void) -> Void)?
    var deleteEmailClosure: ((MCOIMAPMessage, @escaping (Bool) -> Void) -> Void)?
    var replyToEmail: String?
    var replyContent: String?
    var replyToSubject: String?
    private let recipientEmail = UITextField()
    private let subjectLabel = UITextField()
    private let bodyTextView = UITextView()
    
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
            subjectLabel.text = "Re: \(replyToSubject!)"
        }
        
        
        bodyTextView.translatesAutoresizingMaskIntoConstraints = false
        bodyTextView.font = UIFont.systemFont(ofSize: 14)
        if replyContent != nil {
            bodyTextView.text = replyContent
        }
        
        view.addSubview(recipientEmail)
        view.addSubview(subjectLabel)
        view.addSubview(bodyTextView)
        
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
            bodyTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
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
                    let alert = UIAlertController(title: "Failure", message: "mail not sent!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
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
