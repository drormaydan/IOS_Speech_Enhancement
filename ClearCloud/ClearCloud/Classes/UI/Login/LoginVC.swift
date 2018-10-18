//
//  LoginVC.swift
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

class LoginVC: CCViewController {

    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var username: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        makeCloseButton()
    }

    // MARK: - Actions

    @IBAction func clickReset(_ sender: Any) {
        if let url = URL(string: "https://babblelabs.com/account/app/request-password-reset/") {
            UIApplication.shared.open(url, options: [:])
        }
    }

    @IBAction func clickSignup(_ sender: Any) {
        var url_str = "https://babblelabs.com/account/app/register/"
        
        let defaults: UserDefaults = UserDefaults.standard
        if let trial_username = defaults.string(forKey: "trial_username")  {
            url_str = "https://babblelabs.com/account/app/register/?temp_id=\(trial_username)"
        }
        
        if let url = URL(string: url_str) {
            UIApplication.shared.open(url, options: [:])
        }
    }

    @IBAction func clickLogin(_ sender: Any) {
        if (username.text!.count == 0) {
            self.showError(message: "Please enter a username.")
            return
        }
        if (password.text!.count == 0) {
            self.showError(message: "Please enter a password.")
            return
        }

        self.showHud()
        LoginManager.shared.doLogin(username: username.text!, password: password.text!, trial: false) { (status:LoginManager.LoginStatus, error:String?) in
            self.hideHud()
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            case .error:
                self.showError(message: error!)
            case .notLoggedIn:
                break
            }

        }
    }


}
