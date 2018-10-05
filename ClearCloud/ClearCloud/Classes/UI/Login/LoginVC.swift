//
//  LoginVC.swift
//  ClearCloud
//
//  Created by Boris Katok on 10/3/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

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
        if let url = URL(string: "https://babblelabs.com/account/app/register/") {
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
                self.dismiss(animated: true, completion: nil)
            case .error:
                self.showError(message: error!)
            case .notLoggedIn:
                break
            }

        }
    }


}
