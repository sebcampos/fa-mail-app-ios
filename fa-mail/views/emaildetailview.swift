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
    
    private let subjectLabel = UILabel()
    private let fromLabel = UILabel()
    private let dateLabel = UILabel()
    private let bodyTextView = UITextView()
    private var deleteButton: UIButton!

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
        fromLabel.text = "From: \(email.header.sender.displayName ?? "Unknown Sender") \(email.header.sender.mailbox ?? "")"
        dateLabel.text = "Date: \(email.header.date?.description ?? "Unknown Date")"
        
        // Fetch the body using the passed closure
        fetchContentClosure? { [weak self] body in
            DispatchQueue.main.async {
                self?.bodyTextView.text = body
            }
        }
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
