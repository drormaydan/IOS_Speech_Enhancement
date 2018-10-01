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

class AudioVideoCell: UITableViewCell {

    enum AssetType {
        case video
        case audio
    }
    
    var type:AssetType? = nil
    var url:URL? = nil
    var asset:PHAsset? = nil
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var videoView: UIView!
    var owner:ItemDetailVC!
    let av = AVPlayerViewController()
    var loaded = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
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
            print(error.description)
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
