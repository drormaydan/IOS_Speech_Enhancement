//
//  AboutVC.swift
//  ClearCloud
//
//  Created by Boris Katok on 10/3/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit

class AboutVC: CCViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        makeCloseButton()
    }


    @IBAction func clickUrl(_ sender: Any) {
        if let url = URL(string: "https://www.babblelabs.com") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
