//
//  ItemDetailVC.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/21/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.tableFooterView = UIView()
        self.tableView.register(AudioVideoCell.self, forCellReuseIdentifier: "AUDIO_VIDEO_CELL")
        self.tableView.register(UINib(nibName: "AudioVideoCell", bundle: nil), forCellReuseIdentifier: "AUDIO_VIDEO_CELL")
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.backgroundView = nil
        
        if asset.type == .video {
print("ASSET ID \(self.asset.asset!.localIdentifier)")
            let realm = try! Realm()
            self.enhancedVideo = realm.objects(CCEnhancedVideo.self).filter("(original_video_id = %@) OR (enhanced_video_id = %@)", self.asset.asset!.localIdentifier, self.asset.asset!.localIdentifier).first
        }
        
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
            print("UNIQ ID \(self.asset.asset!.localIdentifier)")
        }
        
        self.tableView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    @IBAction func clickEnhance(_ sender: Any) {
        self.doEnhance(self.asset, album: self.album) { (success:Bool, error:String?) in
            self.refresh()
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
            if (self.enhancedVideo == nil) {
                return 1
            }
            return 2

        }
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

            if indexPath.row == 0 {
                if self.enhancedVideo == nil {
                    cell.asset = self.asset.asset!
                } else {
                    let phassets = PHAsset.fetchAssets(withLocalIdentifiers: [self.enhancedVideo!.original_video_id!], options: .none)
                    cell.asset = phassets[0]
                }
            } else {

            }

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
        
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = url
        print("OUTPUT \(url)")
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                success()
            case .unknown, .waiting, .exporting, .failed, .cancelled:
                print("EXPORT STATUS \(exportSession.status.rawValue)")
                let error = NSError(domain: "domain", code: 0, userInfo: nil)
                failure(error)
            }
        }
    }
    
    private func audioAsset() throws -> AVAsset {
        let composition = AVMutableComposition()
        let audioTracks = tracks(withMediaType: AVMediaType.audio)
        
        for track in audioTracks {
            print("track \(track)")
            let compositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionTrack?.insertTimeRange(track.timeRange, of: track, at: track.timeRange.start)
            } catch {
                throw error
            }
            compositionTrack!.preferredTransform = track.preferredTransform
        }
        
        print("composition \(composition)")
        return composition
    }
}

