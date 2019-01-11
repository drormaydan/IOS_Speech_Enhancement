//
//  TutorialVC.swift
//  ClearCloud
//
//  Created by Boris Katok on 1/11/19.
//  Copyright © 2019 Boris Katok. All rights reserved.
//

import UIKit

class TutorialVC: CCViewController {

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

    @IBAction func clickClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func clickDone(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "showed_tutorial")
        UserDefaults.standard.synchronize()
        self.dismiss(animated: true, completion: nil)
    }

}
