//
//  PermissionsInfoVC.swift
//  ClearCloud
//
//  Created by Boris Katok on 1/10/19.
//  Copyright © 2019 Boris Katok. All rights reserved.
//

import UIKit

class PermissionsInfoVC: CCViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func clickNext(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
