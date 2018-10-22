//
//  RegisterVC.swift
//  ClearCloud
//
//  Created by Boris Katok on 10/21/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import WebKit

class RegisterVC: CCViewController, WKNavigationDelegate {

    var url:URL!
    
    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        makeCloseButton()
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
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
