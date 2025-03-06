//
//  newemailview.swift
//  fa-mail
//
//  Created by Sebastian Campos on 3/5/25.
//

import SwiftUI

class NewEmailViewController: UIViewController {
    
    var email: MCOIMAPMessage?
    var smtpSession: MCOSMTPSession!
    var fetchContentClosure: ((@escaping (String) -> Void) -> Void)?
    var deleteEmailClosure: ((MCOIMAPMessage, @escaping (Bool) -> Void) -> Void)?
    private let recipeintEmail = UITextField()
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
        recipeintEmail.translatesAutoresizingMaskIntoConstraints = false
        recipeintEmail.placeholder = "Recipient"
        recipeintEmail.autocapitalizationType = .none
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        subjectLabel.placeholder = "Subject"
        bodyTextView.translatesAutoresizingMaskIntoConstraints = false
        bodyTextView.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(recipeintEmail)
        view.addSubview(subjectLabel)
        view.addSubview(bodyTextView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            recipeintEmail.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            recipeintEmail.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            recipeintEmail.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subjectLabel.topAnchor.constraint(equalTo: recipeintEmail.bottomAnchor, constant: 20),
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
        print("foobar")
    }
    
}
