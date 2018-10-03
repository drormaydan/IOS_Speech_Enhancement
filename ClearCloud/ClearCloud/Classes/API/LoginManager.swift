//
//  LoginManager.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/20/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import RealmSwift

class LoginManager: NSObject {
    
    static let shared: LoginManager = LoginManager()
    
    var logged_in:Bool = false
    
    enum LoginStatus {
        case success
        case error
        case notLoggedIn
    }
    
    func storeUsername(username: String) {
        UserDefaults.standard.set(username, forKey: "username")
    }
    
    func storePassword(password: String) {
        Keychain.storePassword(password: password)
    }
    
    func getUsername() -> String? {
        return UserDefaults.standard.string(forKey: "username")
    }
    
    func getPassword() -> String? {
        return Keychain.loadPassword()
    }
    
    func logout() {
        
        let defaults: UserDefaults = UserDefaults.standard
        defaults.removeObject(forKey: "username")
        defaults.removeObject(forKey: "session_id")
        defaults.set(false, forKey: "trial")
        defaults.set(true, forKey: "did_trial")
        defaults.synchronize()
        Keychain.clear()
        LoginManager.shared.logged_in = false
        BabbleLabsApi.shared.sessionToken = "none"
        // let appDelegate = UIApplication.shared.delegate as! AppDelegate
        // appDelegate.showLogin()
    }
    
    func checkRegistration(completion: @escaping (_ status: LoginStatus, _ error:String?) -> Void) {
        checkRegistration(force: false, completion: completion)
    }
    
    func checkRegistration(force:Bool, completion: @escaping (_ status: LoginStatus, _ error:String?) -> Void) {
       // print("USERNAME \(LoginManager.shared.getUsername()) PASSWORD \(LoginManager.shared.getPassword())")
        if (!force) {
            if logged_in {
                completion(.success,nil)
                return
            }
        }
        
        let defaults: UserDefaults = UserDefaults.standard
        let trial = defaults.bool(forKey: "trial");
        print("TRY LOGIN trial=\(trial)")
        if (LoginManager.shared.getUsername() != nil) && (LoginManager.shared.getPassword() != nil) {
            doLogin(username: LoginManager.shared.getUsername()!, password: LoginManager.shared.getPassword()!, trial:trial, completion: completion)
        } else {
            completion(.notLoggedIn,nil)
        }
    }
    
    
    func doLogin(username:String, password:String, trial:Bool, completion: @escaping (_ status: LoginStatus, _ error:String?) -> Void) {
        
        if trial {
            BabbleLabsApi.shared.mobileLogin(userId: username, password: password) { (error:ServerError?, response:LoginResponse?) in
                if let error = error {
                    completion(.error,error.getMessage()!)
                } else if let response = response {
                    if let auth_token = response.auth_token {
                        self.logged_in = true
                        BabbleLabsApi.shared.sessionToken = auth_token
                        self.storeUsername(username: username)
                        self.storePassword(password: password)
                        NotificationCenter.default.post(name:Notification.Name(rawValue:"LoginNotification"),
                                                        object: nil,
                                                        userInfo: nil)
                        completion(.success,nil)
                    } else {
                        completion(.error,"Sorry, there was a problem. Please try again.")
                    }
                } else {
                    completion(.error,"Sorry, there was a problem. Please try again.")
                }
            }
        } else {
            BabbleLabsApi.shared.login(userId: username, password: password) { (error:ServerError?, response:LoginResponse?) in
                if let error = error {
                    completion(.error,error.getMessage()!)
                } else if let response = response {
                    if let auth_token = response.auth_token {
                        self.logged_in = true
                        BabbleLabsApi.shared.sessionToken = auth_token
                        self.storeUsername(username: username)
                        self.storePassword(password: password)
                        NotificationCenter.default.post(name:Notification.Name(rawValue:"LoginNotification"),
                                                        object: nil,
                                                        userInfo: nil)
                        completion(.success,nil)
                    } else {
                        completion(.error,"Sorry, there was a problem. Please try again.")
                    }
                } else {
                    completion(.error,"Sorry, there was a problem. Please try again.")
                }
            }
        }
    }
    
    
}

