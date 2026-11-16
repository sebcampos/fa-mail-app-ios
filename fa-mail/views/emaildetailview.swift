//
//  emaildetailview.swift
//  fa-mail
//
//  Created by Sebastian Campos on 3/5/25.
//
import SwiftUI
import WebKit

class EmailDetailViewController: UIViewController, WKNavigationDelegate {
    
    var email: MCOIMAPMessage?
    var fetchContentClosure: ((@escaping (String) -> Void) -> Void)?
    var deleteEmailClosure: ((MCOIMAPMessage, @escaping (Bool) -> Void) -> Void)?
    var username: String!
    var smtpSession: MCOSMTPSession!
    var imapSession: MCOIMAPSession?
    
    private let subjectLabel = UILabel()
    private let fromLabel = UILabel()
    private let dateLabel = UILabel()
    private let bodyHtmlView = WKWebView()
    private var plainBody = ""
    private var deleteButton: UIButton!
    private var replyButton: UIButton!
    private var attachmentAlertController: UIAlertController!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Message"
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
        
        bodyHtmlView.isOpaque = false
        bodyHtmlView.backgroundColor = .white
        bodyHtmlView.scrollView.backgroundColor = .white
        bodyHtmlView.navigationDelegate = self
        bodyHtmlView.scrollView.contentInset.bottom = 80
        

        subjectLabel.numberOfLines = 0
        fromLabel.numberOfLines = 0
        dateLabel.numberOfLines = 0

        subjectLabel.lineBreakMode = .byWordWrapping
        fromLabel.lineBreakMode = .byWordWrapping
        dateLabel.lineBreakMode = .byWordWrapping
        
        view.addSubview(subjectLabel)
        view.addSubview(fromLabel)
        view.addSubview(dateLabel)
        view.addSubview(bodyHtmlView)
        
        view.backgroundColor = .systemBackground
        bodyHtmlView.backgroundColor = .white   // email HTML assumes a light page
        
        // Set up constraints
        NSLayoutConstraint.activate([
            subjectLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            subjectLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            subjectLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            fromLabel.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 10),
            fromLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            fromLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            dateLabel.topAnchor.constraint(equalTo: fromLabel.bottomAnchor, constant: 10),
            dateLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            bodyHtmlView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
            bodyHtmlView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            bodyHtmlView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            bodyHtmlView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            let landscape = size.width > size.height
            self.fromLabel.isHidden = landscape
            self.dateLabel.isHidden = landscape
        }, completion: { _ in self.fitToWidth() })
    }
    
    private func fitToWidth() {
        let js = """
        (function(){
          document.body.style.zoom = 1;
          var w = document.documentElement.scrollWidth, v = window.innerWidth;
          if (w > v) { document.body.style.zoom = v / w; }
        })();
        """
        bodyHtmlView.evaluateJavaScript(js)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        fitToWidth()
    }
    
    
    func displayHTMLContent(htmlString: String) {
        if let data = htmlString.data(using: .utf8),
           let attr = try? NSAttributedString(
               data: data,
               options: [.documentType: NSAttributedString.DocumentType.html,
                         .characterEncoding: String.Encoding.utf8.rawValue],
               documentAttributes: nil) {
            plainBody = attr.string
        }
        let page = """
        <html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
        html, body { background:#fff; color:#000; margin:0; padding:0 8px;
                     font-family:-apple-system; overflow-wrap:anywhere; }
        * { max-width:100% !important; box-sizing:border-box; }
        table { width:100% !important; table-layout:auto; }
        td, th { word-break:break-word; }
        img { height:auto !important; }
        pre { white-space:pre-wrap; }
        </style></head>
        <body>\(htmlString)</body></html>
        """
        bodyHtmlView.loadHTMLString(page, baseURL: nil)
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
        replyButton.backgroundColor = .faPurple
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
        newMessageController.imapSession = imapSession
        newMessageController.replyToEmail = email?.header.sender.mailbox
        
        let originalText = plainBody
        
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
                        // Clear the right column when split, otherwise go back
                        if let split = self?.splitViewController, !split.isCollapsed {
                            let blank = UIViewController()
                            blank.view.backgroundColor = .systemBackground
                            split.setViewController(UINavigationController(rootViewController: blank), for: .secondary)
                        } else {
                            self?.navigationController?.popViewController(animated: true)
                        }
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
