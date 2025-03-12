//
//  secretsmanager.swift
//  fa-mail
//
//  Created by Sebastian Campos on 3/7/25.
//
import KeychainAccess

struct Credentials {
    var username: String
    var password: String
}


class MyKeychainManager {

    // let keychain = Keychain(service: "com.friendlyautomations.fa-mail")

    // Store username and password securely in Keychain
    static func storeCredentials(username: String, password: String) -> Bool {
        let credentials = Credentials(username: username, password: password)
        let account = credentials.username
        let password = credentials.password.data(using: String.Encoding.utf8)!
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: account,
                                    kSecAttrServer as String: "mail.friendlyautomations.com",
                                    kSecValueData as String: password]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {return false}
        return true
    }

    // Retrieve username and password from Keychain
    static func retrieveCredentials() -> (username: String?, password: String?) {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: "mail.friendlyautomations.com",
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8),
            let account = existingItem[kSecAttrAccount as String] as? String
        else {
            return (nil, nil)
        }
        let credentials = Credentials(username: account, password: password)
        return (credentials.username, credentials.password)
    }

}

