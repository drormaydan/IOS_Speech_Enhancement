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
    
    func populate() {
        if loaded {
            return
        }
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
            if let phasset = self.asset {
                guard (phasset.mediaType == PHAssetMediaType.video)
                    
                    else {
                        print("Not a valid video media type")
                        return
                }
                
                imageManager.requestAVAsset(forVideo: phasset, options: nil, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) in
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
                    }
                })

            }
            
        }

    }
    
    lazy var imageManager = {
        return PHCachingImageManager()
    }()

}
