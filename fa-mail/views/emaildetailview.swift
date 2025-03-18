//
//  emaildetailview.swift
//  fa-mail
//
//  Created by Sebastian Campos on 3/5/25.
//
import SwiftUI

class EmailDetailViewController: UIViewController {
    
    var email: MCOIMAPMessage?
    var fetchContentClosure: ((@escaping (String) -> Void) -> Void)?
    var deleteEmailClosure: ((MCOIMAPMessage, @escaping (Bool) -> Void) -> Void)?
    var username: String!
    var smtpSession: MCOSMTPSession!
    
    private let subjectLabel = UILabel()
    private let fromLabel = UILabel()
    private let dateLabel = UILabel()
    private let bodyHtmlView = UITextView()
    private var deleteButton: UIButton!
    private var replyButton: UIButton!
    private var attachmentAlertController: UIAlertController!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Email Detail"
        setupViews()
        displayEmailDetails()
        addReplyButton()
        addDeleteButton()
    }

    func setupViews() {
        // Set up the views to display email details
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        fromLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyHtmlView.translatesAutoresizingMaskIntoConstraints = false
        
        bodyHtmlView.isEditable = false
        bodyHtmlView.font = UIFont.systemFont(ofSize: 14)
        
        view.addSubview(subjectLabel)
        view.addSubview(fromLabel)
        view.addSubview(dateLabel)
        view.addSubview(bodyHtmlView)
        
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
            
            bodyHtmlView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
            bodyHtmlView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bodyHtmlView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bodyHtmlView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    
    func displayHTMLContent(htmlString: String) {
         guard let data = htmlString.data(using: .utf8) else { return }

        do {
            // Convert the data to a string so we can modify it
            if let htmlString = String(data: data, encoding: .utf8) {
                let darkModeHTML = """
                <style>
                    body { background-color: black; color: white; }
                </style>
                \(htmlString)
                """
                
                // Convert back to Data
                if let darkModeData = darkModeHTML.data(using: .utf8) {
                    let attributedString = try NSAttributedString(
                        data: darkModeData,
                        options: [.documentType: NSAttributedString.DocumentType.html],
                        documentAttributes: nil
                    )
                    
                    let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
                    
                    // Ensure all text is white
//                    mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: mutableAttributedString.length))
                    
                    // Set the modified attributed string to the UITextView
                    bodyHtmlView.attributedText = mutableAttributedString
                }
            }
        } catch {
            print("Error loading HTML: \(error)")
        }
     }
    

    func displayEmailDetails() {
        guard let email = email else { return }
        
        subjectLabel.text = "Subject: \(email.header.subject ?? "No Subject")"
        fromLabel.text = "From: \(email.header.sender.mailbox ?? "")"
        dateLabel.text = "Date: \(email.header.date?.description ?? "Unknown Date")"
        
        // Fetch the body using the passed closure
        fetchContentClosure? { [weak self] bodyHtml in
            DispatchQueue.main.async {
                //self?.bodyHtmlView.text = " \(email.header.sender.displayName ?? "")\n" + bodyHtml
                self?.displayHTMLContent(htmlString: bodyHtml)
            }
        }
    }
    

    
    func addReplyButton() {
        replyButton = UIButton(type: .custom)
        let iconImage = UIImage(systemName: "arrowshape.turn.up.left")  // Use a download icon
        
        
        replyButton.setImage(iconImage, for: .normal)
        replyButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Make the button circular
        replyButton.layer.cornerRadius = 25
        replyButton.clipsToBounds = true
        replyButton.backgroundColor = .systemIndigo
        replyButton.tintColor = .white
        
        // Action when the button is pressed
        replyButton.addTarget(self, action: #selector(addNewMessage), for: .touchUpInside)

        
        // Add the button to the view
        self.view.addSubview(replyButton)
        
        NSLayoutConstraint.activate([
            replyButton.widthAnchor.constraint(equalToConstant: 50),
            replyButton.heightAnchor.constraint(equalToConstant: 50),
            replyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            replyButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -80)
        ])
    }
    
    
    
    @objc func addNewMessage() {
        let newMessageController = NewEmailViewController()
        newMessageController.smtpSession = smtpSession
        newMessageController.username = username
        newMessageController.replyToEmail = email?.header.sender.mailbox
        let originalText = bodyHtmlView.attributedText.string
        
        // Prefix each line with ">"
        let quotedText = originalText
            .split(separator: "\n")
            .map { "> \($0)" }
            .joined(separator: "\n")
        newMessageController.replyContent = "\n             \n\n------------------------------\n > On \(dateLabel.text ?? "Unknown") \(email?.header.sender.mailbox ?? "Unknown") wrote:\n\n >" + quotedText + "\n"
        newMessageController.replyToSubject = email?.header.subject
        navigationController?.pushViewController(newMessageController, animated: true)
    }
    
    
    
    
    func addDeleteButton() {
        // Create a delete button with an icon
        let iconImage = UIImage(systemName: "trash")
        deleteButton = UIButton(type: .custom)
        
        deleteButton.setImage(iconImage, for: .normal)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Optional: Make the button circular by setting the corner radius
        deleteButton.layer.cornerRadius = 25
        deleteButton.clipsToBounds = true
        deleteButton.backgroundColor = .red
        deleteButton.tintColor = .white
        
        // Add an action for the button tap
        deleteButton.addTarget(self, action: #selector(deleteEmail), for: .touchUpInside)
        
        // Add the button to the view
        self.view.addSubview(deleteButton)
        
        // Add Auto Layout constraints to position the button at the bottom-right corner
        NSLayoutConstraint.activate([
            deleteButton.widthAnchor.constraint(equalToConstant: 50),
            deleteButton.heightAnchor.constraint(equalToConstant: 50),
            deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            deleteButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    @objc func deleteEmail() {
        guard let email = email else { return }
        
        let alert = UIAlertController(title: "Delete Confirm", message: "Delete email?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {[weak self] _ in
            // Call the delete closure to delete the email
            self?.deleteEmailClosure?(email) { [weak self] success in
                if success {
                    // If deletion is successful, pop the current view controller
                    let alert = UIAlertController(title: "Success", message: "mail deleted", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        // Navigate back after sending
                        self?.navigationController?.popViewController(animated: true)
                    }))
                    self?.present(alert, animated: true, completion: nil)
                } else {
                    // Handle the error or show an alert to the user
                    print("Failed to delete email.")
                    let alert = UIAlertController(title: "Failure", message: "mail not deleted!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
