//
//  ItemDetailVC.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/21/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import RealmSwift

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
        
        refresh()
    }

    func refresh() {
        if asset.type == .audio {
            if asset.audio!.enhanced_audio_path == nil {
                self.enhanceButton.isHidden = false
            } else {
                self.enhanceButton.isHidden = true
            }
        } else {
            
        }
        self.tableView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions

    @IBAction func clickEnhance(_ sender: Any) {
        if asset.type == .audio {
            self.showHud()
            if let audio = self.asset.audio {
                let filemgr = FileManager.default
                let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
                let docsDir = dirPaths.first!
                let newDir = docsDir.appendingPathComponent(audio.unique_id!)
                
                let audiourl2 = newDir.appendingPathComponent("enhanced.mp3")
                
                let path = asset.audio!.local_audio_path
                let url = docsDir.appendingPathComponent(path!)

                
                BabbleLabsApi.shared.convertAudio(filepath: url.path, email: LoginManager.shared.getUsername()!, destination: audiourl2) { (success:Bool, error:ServerError? ) in
                    self.hideHud()
                    print("POST SUCCESS \(success) error \(error)")
                    if (success) {
                        DispatchQueue.main.async {
                            let realm = try! Realm()
                            try! realm.write {
                                audio.enhanced_audio_path = audiourl2.path.replacingOccurrences(of: docsDir.path, with: "")
                            }
                            self.refresh()
                        }

                    } else {
                        
                    }
                }
            }
        } else {
            
        }
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
