//
//  ItemDetailVC.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/21/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit

class ItemDetailVC: CCViewController, UITableViewDelegate, UITableViewDataSource {

    var asset:CCAsset!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var enhanceButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.tableFooterView = UIView()
        self.tableView.register(AudioVideoCell.self, forCellReuseIdentifier: "AUDIO_VIDEO_CELL")
        self.tableView.register(UINib(nibName: "AudioVideoCell", bundle: nil), forCellReuseIdentifier: "AUDIO_VIDEO_CELL")
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.backgroundView = nil

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions

    @IBAction func clickEnhance(_ sender: Any) {
    }
    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 217
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if asset.type == .audio {
            if asset.audio!.enhanced_audio_path != nil {
                return 2
            }
            return 1
        } else {
            
            
        }
        
        return 0;
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("END SCROLL")
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:AudioVideoCell = self.tableView.dequeueReusableCell(withIdentifier: "AUDIO_VIDEO_CELL", for: indexPath) as! AudioVideoCell
        if asset.type == .audio {
            cell.type = .audio
            let filemgr = FileManager.default
            let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
            let docsDir = dirPaths.first!

            var path:String? = nil
            if indexPath.row == 0 {
                path = asset.audio!.local_audio_path
            } else {
                path = asset.audio!.enhanced_audio_path
            }
            cell.url = docsDir.appendingPathComponent(path!)
        } else {
            cell.type = .video

            
        }
        cell.selectionStyle = .none
        cell.owner = self
        cell.populate()
        return cell
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
