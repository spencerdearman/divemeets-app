//
//  keychain.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 4/21/23.
//

import Foundation
import Security
import LocalAuthentication

class KeychainManager {
    
    // Create a new keychain item with biometric authentication for the username and password fields
    func createKeychainItem(divemeetsID: String, password: String) {
        let service = "com.LoganSherwin-SpencerDearman.DiveMeets" // Set your own unique service identifier here
        let account = divemeetsID
        let passwordData = password.data(using: .utf8)!
        
        let accessControl = SecAccessControlCreateWithFlags(nil, // Use the default security descriptor
                                                             kSecAttrAccessibleWhenUnlockedThisDeviceOnly, // Only allow access when the device is unlocked
                                                             .biometryCurrentSet, // Require biometric authentication
                                                             nil) // Use the default error handling
        
        let context = LAContext()
        context.interactionNotAllowed = true
        
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData,
            kSecAttrAccessControl as String: accessControl!,
            kSecUseAuthenticationContext as String: context,
            kSecReturnAttributes as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemAdd(attributes as CFDictionary, &item)
        guard status == errSecSuccess else {
            print("Failed to add keychain item with error: \(status)")
            return
        }
        
        let result = item as! [String: Any]
        print("Created keychain item with attributes: \(result)")
    }

    
    // Retrieve the password from the keychain item with biometric authentication for the username and password fields
    func retrievePasswordForDivemeetsID(divemeetsID: String) -> String? {
        let service = "com.LoganSherwin-SpencerDearman.DiveMeets" // Set your own unique service identifier here
        let account = divemeetsID
        
        let context = LAContext()
        context.interactionNotAllowed = true
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseAuthenticationContext as String: context,
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            print("Failed to retrieve keychain item with error: \(status)")
            return nil
        }
        
        let result = item as! [String: Any]
        let passwordData = result[kSecValueData as String] as! Data
        let password = String(data: passwordData, encoding: .utf8)!
        
        print("Retrieved password for divemeetsID '\(divemeetsID)': \(password)")
        return password
    }
}
