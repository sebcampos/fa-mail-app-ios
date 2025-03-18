//
//  emaildetailview.swift
//  fa-mail
//
//  Created by Sebastian Campos on 3/5/25.
//
import SwiftUI

class EmailDetailViewController: UIViewController, UIDocumentPickerDelegate {
    
    var email: MCOIMAPMessage?
    var fetchContentClosure: ((@escaping (String, [Any], String) -> Void) -> Void)?
    var deleteEmailClosure: ((MCOIMAPMessage, @escaping (Bool) -> Void) -> Void)?
    
    private let subjectLabel = UILabel()
    private let fromLabel = UILabel()
    private let dateLabel = UILabel()
    private let bodyTextView = UITextView()
    private var deleteButton: UIButton!
    private var attachmentAlertController: UIAlertController!

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
    
    
    func displayHTMLContent(htmlString: String) {
         guard let data = htmlString.data(using: .utf8) else { return }

         do {
             let attributedString = try NSAttributedString(
                 data: data,
                 options: [.documentType: NSAttributedString.DocumentType.html],
                 documentAttributes: nil
             )
             let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
             mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: mutableAttributedString.length))

             bodyTextView.attributedText = mutableAttributedString
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
        fetchContentClosure? { [weak self] body, attachments, bodyHtml in
            DispatchQueue.main.async {
                //self?.bodyTextView.text = " \(email.header.sender.displayName ?? "")\n" + bodyHtml
                self?.displayHTMLContent(htmlString: bodyHtml)
                var mcoAttachments: [MCOAttachment] = []
                for attachment in attachments {
                    if let mcoAttachment = attachment as? MCOAttachment {
                        mcoAttachments.append(mcoAttachment)
                    } else {
                        print("Found non-MCOAttachment object in the attachments array.")
                    }
                }
        
                if !mcoAttachments.isEmpty {
                    self?.addDownloadButton(for: mcoAttachments)
                }
                
                
            }
        }
    }
    
    func handleICSFile(_ icsData: Data) {
        // First, let's try to open the .ics file using UIDocumentInteractionController.
        // We'll save it to a temporary file, and let the user open it with the default app (Calendar).
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("attachment.ics")
        
        do {
            // Write the .ics data to a temporary file
            try icsData.write(to: fileURL)
            UIApplication.shared.open(fileURL, options: [:], completionHandler: nil)
            // Now, create a document interaction controller to open the file
//            let documentController = UIDocumentPickerViewController(url: fileURL, in: .exportToService)
//            documentController.delegate = self
//            present(documentController, animated: true, completion: nil)
            
        } catch {
            print("Failed to save .ics file: \(error)")
        }
    }
    
    
    func addDownloadButton(for attachments: [MCOAttachment]) {
        let iconImage = UIImage(systemName: "square.and.arrow.down")  // Use a download icon
        let downloadAttachmentButton = UIButton(type: .custom)
        
        downloadAttachmentButton.setImage(iconImage, for: .normal)
        downloadAttachmentButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Make the button circular
        downloadAttachmentButton.layer.cornerRadius = 25
        downloadAttachmentButton.clipsToBounds = true
        downloadAttachmentButton.backgroundColor = .systemIndigo
        downloadAttachmentButton.tintColor = .white
        
        
        
        attachmentAlertController = UIAlertController(title: "Choose Attachment", message: "Please select an attachment.", preferredStyle: .alert)
        for (index, attachment) in attachments.enumerated() {
            // Create a button to download the attachment
            let actionTitle = attachment.filename ?? "\(index + 1) \(attachment.mimeType!)"
            attachmentAlertController.addAction(UIAlertAction(title: actionTitle, style: .default, handler: {[weak self] _ in
                self?.openAttachment(attachment)
            }))
        }
        
        // Action when the button is pressed
        downloadAttachmentButton.addTarget(self, action: #selector(showAttachmentPopup), for: .touchUpInside)

        
        // Add the button to the view
        self.view.addSubview(downloadAttachmentButton)
        
        NSLayoutConstraint.activate([
            downloadAttachmentButton.widthAnchor.constraint(equalToConstant: 50),
            downloadAttachmentButton.heightAnchor.constraint(equalToConstant: 50),
            downloadAttachmentButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            downloadAttachmentButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -80)
        ])
    }
    
    
    func openAttachment(_ attachment: MCOAttachment) {
        guard let mimeType = attachment.mimeType else { return }
        print(mimeType)
        // If it's an image, we can display it in an image view
        
        if mimeType == "application/ics" || mimeType == "text/calendar" {
            // Handle the .ics attachment
            
            // First, let's check if we have the attachment data.
            if let data = attachment.data {
                // Parse or open the .ics data
                handleICSFile(data)
            } else {
                print("No data found for attachment.")
            }
            
        }
    }
    
    
    @objc func showAttachmentPopup() {
        self.present(attachmentAlertController, animated: true, completion: nil)
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
