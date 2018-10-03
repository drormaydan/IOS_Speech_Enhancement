//
//  LeftNavVC.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/18/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit

class LeftNavVC: CCViewController, UITableViewDelegate, UITableViewDataSource {

    let menus = ["Support", "About Us", "Logout"]
    let icons = [UIImage.init(named: "support"), UIImage.init(named: "about"),UIImage.init(named: "logout")]

    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet var tableheader: UIView!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.tableFooterView = UIView()
        tableView.tableHeaderView = self.tableheader
        self.tableView.register(NavCell.self, forCellReuseIdentifier: "NAV_CELL")
        self.tableView.register(UINib(nibName: "NavCell", bundle: nil), forCellReuseIdentifier: "NAV_CELL")
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.backgroundView = nil

        self.username.isHidden = true
        self.email.isHidden = true
        
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"LoginNotification"),
                                               object:nil, queue:nil,
                                               using:catchNotification)

    }

    func catchNotification(notification: Notification) -> Void {
        print("GOT NOTIFICATION \(LoginManager.shared.logged_in)")
        DispatchQueue.main.async {
            if LoginManager.shared.logged_in {
                let defaults: UserDefaults = UserDefaults.standard
                let trial = defaults.bool(forKey: "trial")
                if trial {
                    self.username.isHidden = false
                    self.username.text = "Free Trial"
                    self.email.isHidden = true
                } else {
                    OktaApi.shared.getUser(email: LoginManager.shared.getUsername()!, completionHandler: { (error:ServerError?, response:UserResponse?) in
                        if let response = response {
                            
                            if let profile = response.profile {
                                DispatchQueue.main.async {
                                    self.username.isHidden = false
                                    self.email.isHidden = false
                                    self.username.text = "\(profile.firstName!) \(profile.lastName!)"
                                    self.email.text = LoginManager.shared.getUsername()!
                                }
                            }
                        }
                    })
                }
            } else {
                self.username.isHidden = true
                self.email.isHidden = true
            }
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.menus.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:NavCell = self.tableView.dequeueReusableCell(withIdentifier: "NAV_CELL", for: indexPath) as! NavCell
       
        cell.navimage.image = self.icons[indexPath.row]
        cell.navlabel.text = self.menus[indexPath.row]

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        
        switch indexPath.row {
        case 0:
            if let url = URL(string: "mailto:support@babblelabs.com?subject=Babblelabs%20iPhone%20App%20Support") {
                UIApplication.shared.open(url, options: [:])
            }
        case 1:
            let albumsVC:AboutVC = AboutVC(nibName: "AboutVC", bundle: nil)
            let nav:UINavigationController = UINavigationController(rootViewController: albumsVC)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.sideMenuController.present(nav, animated: true, completion: nil)
        case 2:
            LoginManager.shared.logout()
            NotificationCenter.default.post(name:Notification.Name(rawValue:"LoginNotification"),
                                            object: nil,
                                            userInfo: nil)
            /*
            let albumsVC:LoginVC = LoginVC(nibName: "LoginVC", bundle: nil)
            let nav:UINavigationController = UINavigationController(rootViewController: albumsVC)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.sideMenuController.present(nav, animated: true, completion: nil)*/
        default:
            break
        }
    
    }
}
