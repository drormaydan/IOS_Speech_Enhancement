//
//  ItemDetailVC.swift
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
import RealmSwift
import AVFoundation
import Photos

class ItemDetailVC: CCViewController, UITableViewDelegate, UITableViewDataSource {

    var asset:CCAsset!
    var enhancedVideo:CCEnhancedVideo? = nil
    var album:Album!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var enhanceButton: UIButton!
    var reload = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.tableFooterView = UIView()
        self.tableView.register(AudioVideoCell.self, forCellReuseIdentifier: "AUDIO_VIDEO_CELL")
        self.tableView.register(UINib(nibName: "AudioVideoCell", bundle: nil), forCellReuseIdentifier: "AUDIO_VIDEO_CELL")
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.backgroundView = nil
        
        if asset.type == .video {
            //print("ASSET ID \(self.asset.asset!.localIdentifier)")
            let realm = try! Realm()
            self.enhancedVideo = realm.objects(CCEnhancedVideo.self).filter("(original_video_id = %@) OR (enhanced_video_id = %@)", self.asset.asset!.localIdentifier, self.asset.asset!.localIdentifier).first
            //print("self.enhancedVideo \(self.enhancedVideo)")
            
            
            if self.enhancedVideo != nil {
                
                // make sure that either video exists
                if let original_video_id = self.enhancedVideo!.original_video_id {
                    let phassets = PHAsset.fetchAssets(withLocalIdentifiers: [original_video_id], options: .none)
                    if phassets.count == 0 {
                        // original was deleted
                        let realm = try! Realm()
                        try! realm.write {
                            self.enhancedVideo!.original_video_id = nil
                        }
                    }
                    
                }
                if let enhanced_video_id = self.enhancedVideo!.enhanced_video_id {
                    let phassets = PHAsset.fetchAssets(withLocalIdentifiers: [enhanced_video_id], options: .none)
                    if phassets.count == 0 {
                        // enhanced was deleted
                        let realm = try! Realm()
                        try! realm.write {
                            self.enhancedVideo!.enhanced_video_id = nil
                        }
                    }
                }
                
                if self.enhancedVideo!.enhanced_video_id == nil && self.enhancedVideo!.original_video_id == nil {
                    let realm = try! Realm()
                    try! realm.write {
                        realm.delete(self.enhancedVideo!);
                        self.showError(message: "The enhanced and original videos have been deleted outside the app.")
                        self.navigationController!.popViewController(animated: true)
                    }
                } else if self.enhancedVideo!.enhanced_video_id != nil {
                    // make enhanced the original
                    let realm = try! Realm()
                    try! realm.write {
                        self.enhancedVideo!.original_video_id = self.enhancedVideo!.enhanced_video_id
                    }
                }
                
            }
            
        } else {
            // tmp fix audio
            /*
            let filemgr = FileManager.default
            let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
            let docsDir = dirPaths.first!
            let origurl = docsDir.appendingPathComponent(asset.audio!.local_audio_path!)

            let audiourl2 : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(self.asset.audio!.unique_id!)_fixed2.m4a")
            let audiourl3 : URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/\(self.asset.audio!.unique_id!)_backup.m4a")

            
            //print("ORIGINAL AUDIO \(audiourl2)")
            self.rewriteAudioFile(audioUrl: origurl, outputUrl: audiourl2, completion: { (success:Bool, error:String?) in
                if success {
                    do {
                        try filemgr.copyItem(at: origurl, to: audiourl3)
                        //print("SAVED AUDIO TO \(audiourl3)")
                        try filemgr.removeItem(at: origurl)
                        try filemgr.copyItem(at: audiourl2, to: origurl)
                        //print("REWROTE AUDIO TO \(origurl)")
                    } catch {
                        //print("audio Error: \(error)")
                    }
                    
                }
                
            })*/
        }
        
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        NotificationCenter.default.post(name:Notification.Name(rawValue:"StopPlayers"),
                                        object: nil,
                                        userInfo: nil)
        
        super.viewWillDisappear(animated)
    }

    
    func refresh() {
        DispatchQueue.main.async {
            //print("REFRESH \(self.enhancedVideo)")

            if self.asset.type == .audio {
                if self.asset.audio!.enhanced_audio_path == nil {
                    self.enhanceButton.isHidden = false
                } else {
                    self.enhanceButton.isHidden = true
                }
            } else {
                if let enhancedVideo = self.enhancedVideo {
                    if enhancedVideo.enhanced_video_id == nil {
                        self.enhanceButton.isHidden = false
                    } else {
                        self.enhanceButton.isHidden = true
                    }
                } else {
                    self.enhanceButton.isHidden = false
                }
            }
            
            self.reload = true
            self.tableView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.reload = false
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    @IBAction func clickEnhance(_ sender: Any) {
        NotificationCenter.default.post(name:Notification.Name(rawValue:"StopPlayers"),
                                        object: nil,
                                        userInfo: nil)

        self.showHud(message: "Enhancing...")
        self.doEnhance(self.asset, album: self.album) { (success:Bool, error:String?) in
            self.hideHud()
            //print("DONE ENHANCE")
            if success {
                if self.asset.type == .video {
                    //print("REFRESH ASSET ID \(self.asset.asset!.localIdentifier)")
                    let realm = try! Realm()
                    realm.refresh()
                    self.enhancedVideo = realm.objects(CCEnhancedVideo.self).filter("(original_video_id = %@) OR (enhanced_video_id = %@)", self.asset.asset!.localIdentifier, self.asset.asset!.localIdentifier).first
                    //print("NEW ENHANCED ID \(self.enhancedVideo!.enhanced_video_id)")
                }
                
                self.refresh()
            } else {
                //print("ENHANCE ERROR \(error)")
                self.showError(message: error!)
            }
        }
    }
    

    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //return 311
        return UIScreen.main.bounds.height * 0.35
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
            if (self.enhancedVideo == nil) {
                return 1
            }
            if self.enhancedVideo!.enhanced_video_id == nil {
                return 1
            }
            return 2

        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //print("END SCROLL")
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
                cell.typeLabel.text = "Original"
            } else {
                path = asset.audio!.enhanced_audio_path
                cell.typeLabel.text = "Enhanced"
            }
            if path != nil {
                cell.url = docsDir.appendingPathComponent(path!)
            }
        } else {
            cell.type = .video

            if indexPath.row == 0 {
                if self.enhancedVideo == nil {
                    //print("@@@self.asset \(self.asset) \(self.asset.asset)")

                    cell.asset = self.asset.asset!
                } else {
                    ////print("TRY FETCH \(self.enhancedVideo!.original_video_id!)")
                    let phassets = PHAsset.fetchAssets(withLocalIdentifiers: [self.enhancedVideo!.original_video_id!], options: .none)
                    if phassets.count > 0 {
                        cell.asset = phassets[0]
                    } else {
                        cell.asset = self.asset.asset!
                    }
                }
                cell.typeLabel.text = "Original"
            } else {
                if let enhanced_video_id = self.enhancedVideo!.enhanced_video_id {
                    let phassets = PHAsset.fetchAssets(withLocalIdentifiers: [enhanced_video_id], options: .none)
                    if phassets.count > 0 {
                        cell.asset = phassets[0]
                    }
                }
                cell.typeLabel.text = "Enhanced"
            }
        }

        cell.selectionStyle = .none
        cell.owner = self
        if self.reload {
            cell.loaded = false
        }
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
extension AVAsset {
    func writeAudioTrack(to url: URL, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        do {
            let asset = try audioAsset()
            asset.write(to: url, success: success, failure: failure)
        } catch {
            failure(error)
        }
    }
    
    private func write(to url: URL, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetAppleM4A) else {
            let error = NSError(domain: "domain", code: 0, userInfo: nil)
            failure(error)
            
            return
        }
        
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = url
        //print("OUTPUT \(url)")
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                success()
            case .unknown, .waiting, .exporting, .failed, .cancelled:
                //print("EXPORT STATUS \(exportSession.status.rawValue)")
                let error = NSError(domain: "domain", code: 0, userInfo: nil)
                failure(error)
            }
        }
    }
    
    private func audioAsset() throws -> AVAsset {
        let composition = AVMutableComposition()
        let audioTracks = tracks(withMediaType: AVMediaType.audio)
        
        for track in audioTracks {
            //print("track \(track)")
            let compositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionTrack?.insertTimeRange(track.timeRange, of: track, at: track.timeRange.start)
            } catch {
                throw error
            }
            compositionTrack!.preferredTransform = track.preferredTransform
        }
        
        //print("composition \(composition)")
        return composition
    }
}

