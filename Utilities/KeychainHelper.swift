//
//  KeychainHelper.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

import SwiftUICore
import Security

class KeychainHelper {
    static func hasValidToken() -> Bool {
        // Check Keychain or UserDefaults for existing token
        if let token = read(service: "funko-auth", account: "current-user") {
            return !token.isEmpty
        }
        return false
    }
    
    static func save(service: String = "funko-auth", account: String = "current-user", token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func read(service: String = "funko-auth", account: String = "current-user") -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, 
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    static func delete(service: String, account: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    static func logout() {
        // Remove auth token
        let tokenQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "current-user"
        ]
        SecItemDelete(tokenQuery as CFDictionary)
        
        // Remove any other user-related keychain items
        // ...
    }
}
