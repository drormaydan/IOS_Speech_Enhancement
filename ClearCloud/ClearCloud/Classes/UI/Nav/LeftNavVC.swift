//
//  LeftNavVC.swift
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
                                    if let username = LoginManager.shared.getUsername() {
                                        self.email.text = username
                                    }
                                }
                            }
                        }
                    })
                }
            } else {
                self.username.isHidden = true
                self.email.isHidden = true
            }
            
            self.tableView.reloadData()
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
        if LoginManager.shared.logged_in {
            let defaults: UserDefaults = UserDefaults.standard
            let trial = defaults.bool(forKey: "trial")
            if !trial {
                return 2
            }

        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if LoginManager.shared.logged_in {
                let defaults: UserDefaults = UserDefaults.standard
                let trial = defaults.bool(forKey: "trial")
                if !trial {
                    return 1
                }
                
            }
            return 0
        }
        
        return self.menus.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:NavCell = self.tableView.dequeueReusableCell(withIdentifier: "NAV_CELL", for: indexPath) as! NavCell
        
        if indexPath.section == 0 {
            cell.navlabel.text = "Add Money"
            cell.navimage.image = UIImage.init(named: "payment")!.withRenderingMode(.alwaysOriginal)
        } else {
            cell.navimage.image = self.icons[indexPath.row]
            cell.navlabel.text = self.menus[indexPath.row]
            
            if self.menus[indexPath.row] == "Logout" {
                let defaults: UserDefaults = UserDefaults.standard
                let trial = defaults.bool(forKey: "trial")
                if trial {
                    cell.navlabel.text = "Login"
                } else if !LoginManager.shared.logged_in {
                    cell.navlabel.text = "Login"
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        if indexPath.section == 0 {
            ClearCloudProducts.store.requestProducts{ [weak self] success, products in
                guard let self = self else { return }
                if success {
                    print("PRODUCTS \(products)")
                    let product = products![0]
                    ClearCloudProducts.store.buyProduct(product)

                }
                
            }

        } else {
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
                let defaults: UserDefaults = UserDefaults.standard
                let trial = defaults.bool(forKey: "trial")
                if trial || !LoginManager.shared.logged_in {
                    
                    let albumsVC:LoginVC = LoginVC(nibName: "LoginVC", bundle: nil)
                    let nav:UINavigationController = UINavigationController(rootViewController: albumsVC)
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.sideMenuController.present(nav, animated: true, completion: nil)
                } else {
                    
                    LoginManager.shared.logout()
                    NotificationCenter.default.post(name:Notification.Name(rawValue:"LoginNotification"),
                                                    object: nil,
                                                    userInfo: nil)
                }
            default:
                break
            }
        }
    }
}
