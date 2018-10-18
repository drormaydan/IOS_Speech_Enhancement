//
//  Keychain.swift
//  ClearCloud
//
/*
 * Copyright (c) 2018 by BabbleLabs, Inc.  ALL RIGHTS RESERVED.
 * These coded instructions, statements, and computer programs are the
 * copyrighted works and confidential proprietary information of BabbleLabs, Inc.
 * They may not be modified, copied, reproduced, distributed, or disclosed to
 * third parties in any manner, medium, or form, in whole or in part, without
 * the prior written consent of BabbleLabs, Inc.
 */

import UIKit

class Keychain: NSObject {
    fileprivate static let userAccount: String = "username"
    fileprivate static let passwordKey: String = "password"
    
    fileprivate static let kSecClassGenericPasswordValue: NSString = NSString(format: kSecClassGenericPassword)
    fileprivate static let kSecClassValue: NSString = NSString(format: kSecClass)
    fileprivate static let kSecAttrServiceValue: NSString = NSString(format: kSecAttrService)
    fileprivate static let kSecAttrAccountValue: NSString = NSString(format: kSecAttrAccount)
    fileprivate static let kSecValueDataValue: NSString = NSString(format: kSecValueData)
    fileprivate static let kSecReturnDataValue: NSString = NSString(format: kSecReturnData)
    fileprivate static let kSecMatchLimitValue: NSString = NSString(format: kSecMatchLimit)
    fileprivate static let kSecMatchLimitOneValue: NSString = NSString(format: kSecMatchLimitOne)
    
    public static func storePassword(password: String) {
        save(service: passwordKey, data: password)
    }
    
    public static func loadPassword() -> String? {
        return load(service: passwordKey)
    }
    
    
    public static func clear() {
        delete(service: passwordKey)
    }
    
    
    fileprivate static func save(service: String, data: String) {
        if let dataFromString = data.data(using: .utf8) {
            let keychainQuery = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, userAccount, dataFromString], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecValueDataValue])
            SecItemDelete(keychainQuery as CFDictionary)
            SecItemAdd(keychainQuery as CFDictionary, nil)
        }
    }
    
    fileprivate static func load(service: String) -> String? {
        let keychainQuery = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, userAccount, kCFBooleanTrue, kSecMatchLimitOneValue], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue, kSecMatchLimitValue])
        
        var dataTypeRef: AnyObject?
        
        let status = SecItemCopyMatching(keychainQuery, &dataTypeRef)
        var contentsOfKeychain: String? = nil
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                contentsOfKeychain = String(data: retrievedData, encoding: .utf8)
            }
        } else {
            print("Error. Status code \(status)")
        }
        
        return contentsOfKeychain
    }
    
    
    fileprivate static func delete(service: String) {
        let keychainQuery = NSMutableDictionary(objects: [kSecClassGenericPasswordValue], forKeys: [kSecClassValue])
        let status = SecItemDelete(keychainQuery)
        if status == errSecSuccess {
            print("deleted keychain")
        } else {
            print("Error. Status code \(status)")
        }
    }
    
}

