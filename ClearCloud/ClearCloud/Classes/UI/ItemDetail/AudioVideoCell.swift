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

class AudioVideoCell: UITableViewCell {

    enum AssetType {
        case video
        case audio
    }
    
    var type:AssetType? = nil
    var url:URL? = nil
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
        print("PLAYER URL \(url!)")
       // let player = AVPlayer(url: url!)
        
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

        player.play()

    }
}
