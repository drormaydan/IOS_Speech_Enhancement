//
//  AudioVideoCell.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/21/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Photos
import RealmSwift

class AudioVideoCell: UITableViewCell {

    enum AssetType {
        case video
        case audio
    }
    
    var type:AssetType? = nil
    var url:URL? = nil
    var asset:PHAsset? = nil
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var videoView: UIView!
    var owner:ItemDetailVC!
    let av = AVPlayerViewController()
    var loaded = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        NotificationCenter.default.addObserver(forName:Notification.Name(rawValue:"StopPlayers"),
                                               object:nil, queue:nil,
                                               using:catchNotification)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func catchNotification(notification: Notification) -> Void {

        DispatchQueue.main.async {
            if let player = self.av.player {
                player.pause()
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func clickEdit(_ sender: Any) {
    
        let alertController = UIAlertController(title: "Set Name", message: "", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: {
            alert -> Void in
            
            let firstTextField = alertController.textFields![0] as UITextField
            
            
            let realm = try! Realm()
            print("realm \(realm)")
            try! realm.write {
                if self.typeLabel.text == "Original" {
                    self.owner.asset.audio!.name = firstTextField.text!
                } else {
                    self.owner.asset.audio!.enhanced_name = firstTextField.text!
                }
            }
            print("done realm")
            self.setNames()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
            
        })
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Audio Name"
            if self.typeLabel.text == "Original" {
                if let name = self.owner.asset.audio!.name {
                    textField.text = name
                }
            } else {
                if let name = self.owner.asset.audio!.enhanced_name {
                    textField.text = name
                }
            }
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.owner.present(alertController, animated: true, completion: nil)

    }
 
    
    @IBAction func clickDelete(_ sender: Any) {
        if (type == .audio) {
            
            let alertController = UIAlertController(title: NSLocalizedString("Are you sure you would like to delete this audio?", comment: ""), message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title:NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { action in

            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { action in
                // delete
                let realm = try! Realm()
                if (self.typeLabel.text! == "Enhanced")  {

                    // just delete the path
                    if FileManager.default.fileExists(atPath: self.url!.path) {
                        do {
                            try FileManager.default.removeItem(atPath: self.url!.path)
                        }
                        catch {
                            print("Could not remove file at url: \(self.url)")
                        }
                    }

                    try! realm.write {
                        self.owner.asset.audio!.enhanced_audio_path = nil
                    }

                    self.owner.refresh()

                } else {
                    
                    if FileManager.default.fileExists(atPath: self.url!.path) {
                        do {
                            try FileManager.default.removeItem(atPath: self.url!.path)
                        }
                        catch {
                            print("Could not remove file at url: \(self.url)")
                        }
                    }

                    try! realm.write {
                        self.owner.asset.audio!.local_audio_path = self.owner.asset.audio!.enhanced_audio_path
                        self.owner.asset.audio!.enhanced_audio_path = nil
                    }
                    
                    if (self.owner.asset.audio!.local_audio_path == nil) {
                        try! realm.write {
                            realm.delete(self.owner.asset.audio!)
                        }
                    }
                    self.owner.navigationController!.popViewController(animated: true)

                    
                }
            }))
            self.owner.present(alertController, animated: true, completion: nil)

        } else {

            let arrayToDelete = NSArray(object: self.asset!)
            
            
            PHPhotoLibrary.shared().performChanges( {
                PHAssetChangeRequest.deleteAssets(arrayToDelete)},
                                                    completionHandler: {
                                                        success, error in
                                                        print("Finished deleting asset. \(success)")
                                                        DispatchQueue.main.async {
                                                            
                                                            let realm = try! Realm()
                                                            let enhancedVideo = realm.objects(CCEnhancedVideo.self).filter("(original_video_id = %@) OR (enhanced_video_id = %@)", self.asset!.localIdentifier, self.asset!.localIdentifier).first
                                                            
                                                            if (self.typeLabel.text! == "Enhanced")  {
                                                                if let enhancedVideo = enhancedVideo {
                                                                    try! realm.write {
                                                                        enhancedVideo.enhanced_video_id = nil
                                                                    }
                                                                    self.owner.refresh()
                                                                }
                                                                
                                                                
                                                            } else {
                                                                if let enhancedVideo = enhancedVideo {
                                                                    try! realm.write {
                                                                        realm.delete(enhancedVideo)
                                                                    }
                                                                    self.owner.navigationController!.popViewController(animated: true)
                                                                } else {
                                                                    
                                                                    self.owner.navigationController!.popViewController(animated: true)
                                                                }
                                                                
                                                                
                                                            }
                                                        }
            })
            
            
        }
    }
    
    
    @IBAction func clickShare(_ sender: Any) {
        
        if (type == .audio) {
            
            let activityViewController = UIActivityViewController(activityItems: [url!], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.shareButton // so that iPads won't crash
            self.owner.present(activityViewController, animated: true, completion: nil)

        } else {
            let options = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: self.asset!, options: options) {
                (avAsset: AVAsset?, avAudioMix: AVAudioMix?, info: [AnyHashable : Any]?) in
                if let videoUrl = (avAsset as? AVURLAsset)?.url {
                    DispatchQueue.main.async {
                        let activityViewController = UIActivityViewController(activityItems: [videoUrl] , applicationActivities: nil)
                        activityViewController.popoverPresentationController?.sourceView = self.shareButton // so that iPads won't crash
                        self.owner.present(activityViewController, animated: true, completion: nil)
                    }
                }
            }
            
        }
    }
    func setNames() {
        if (type == .audio) {
            editButton.isHidden = false
            nameLabel.isHidden = true
            if self.typeLabel.text == "Original" {
                if let name = self.owner.asset.audio!.name {
                    nameLabel.isHidden = false
                    nameLabel.text = name
                }
            } else {
                if let name = self.owner.asset.audio!.enhanced_name {
                    nameLabel.isHidden = false
                    nameLabel.text = name
                }
            }
        } else {
            nameLabel.isHidden = true
            editButton.isHidden = true
        }
    }
    
    func populate() {
        if loaded {
            return
        }
        self.setNames()
        loaded = true
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try? AVAudioSession.sharedInstance().setActive(true)

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient, with: [.mixWithOthers, .allowBluetooth])
            //  try AVAudioSession.sharedInstance().setMode(AVAudioSessionModeVideoRecording)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            //print(error.description)
        }

        if (type == .audio) {
            let avPlayerItem = AVPlayerItem.init(url: url! as URL)
            let player = AVPlayer.init(playerItem: avPlayerItem)
            
            
            av.player = player
            av.view.frame = self.videoView.frame
            self.owner.addChildViewController(av)
            self.videoView.addSubview(av.view)
            //self.videoView.sendSubview(toBack: av.view)
            av.didMove(toParentViewController: self.owner)
            av.videoGravity = AVLayerVideoGravity.resizeAspectFill.rawValue
            av.view.boundInside(superView: self.videoView)
            
            //player.play()
        } else {
            print("@@@VIDEO ASSET -->\(self.asset)")
            if let phasset = self.asset {
                guard (phasset.mediaType == PHAssetMediaType.video)
                    
                    else {
                        print("Not a valid video media type")
                        return
                }
                print("@@@BEFORE GET PHASSET -->\(self.asset)")
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                self.owner.showHud()
                imageManager.requestAVAsset(forVideo: phasset, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) in
                    self.owner.hideHud()
                    if let avAsset = asset {
                        DispatchQueue.main.async {
                            print("GOT ASSET \(avAsset)")

                            let avPlayerItem = AVPlayerItem(asset: avAsset)
                            let player = AVPlayer.init(playerItem: avPlayerItem)
                            
                            self.av.player = player
                            self.av.view.frame = self.videoView.frame
                            self.owner.addChildViewController(self.av)
                            self.videoView.addSubview(self.av.view)
                            //self.videoView.sendSubview(toBack: av.view)
                            self.av.didMove(toParentViewController: self.owner)
                            self.av.videoGravity = AVLayerVideoGravity.resizeAspectFill.rawValue
                            self.av.view.boundInside(superView: self.videoView)
                        }
                    } else {
                        self.owner.showError(message: "Could not read video from album.")
                    }
                })

            } else {
                self.owner.showError(message: "Could not read video from album.")
            }
            
        }

    }
    
    lazy var imageManager = {
        return PHCachingImageManager()
    }()

}
