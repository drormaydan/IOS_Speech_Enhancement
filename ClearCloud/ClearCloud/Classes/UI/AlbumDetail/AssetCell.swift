//
//  AssetCell.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/18/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import Photos
import RealmSwift

class AssetCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    var asset:CCAsset!
    var owner:AlbumDetailVC!
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var enhancedLabel: UIImageView!
    @IBOutlet weak var checkmark: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.durationLabel.backgroundColor = UIColor.init(hex: "#000000", alpha: 0.3)
    }
    
    func populate() {
        
        if (self.asset.type == .add) {
            self.thumbnail.image = #imageLiteral(resourceName: "blue_plus")
            self.durationLabel.isHidden = true
            self.checkmark.isHidden = true
            self.enhancedLabel.isHidden = true
        } else {
            self.checkmark.isHidden = true
            if self.owner.select_mode && asset.selected {
                self.checkmark.isHidden = false
            }
            
            if (self.asset.type == .video) {
                
                self.durationLabel.isHidden = false
                let manager = PHImageManager.default()
                let option = PHImageRequestOptions()
                var thumb = UIImage()
                option.isSynchronous = true
                manager.requestImage(for: self.asset.asset!, targetSize: CGSize(width: self.thumbnail.frame.width, height: self.thumbnail.frame.height), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
                    thumb = result!
                })
                self.thumbnail.image = thumb
                
                let formatter = DateComponentsFormatter()
                formatter.unitsStyle = .positional
                formatter.allowedUnits = [ .minute, .second ]
                formatter.zeroFormattingBehavior = [ .pad ]
                
                self.durationLabel.text = formatter.string(from: self.asset.asset!.duration)
                
                self.enhancedLabel.isHidden = true
                let realm = try! Realm()
                let enhancedVideo = realm.objects(CCEnhancedVideo.self).filter("(original_video_id = %@) OR (enhanced_video_id = %@)", self.asset.asset!.localIdentifier, self.asset.asset!.localIdentifier).first
                if let enhancedVideo = enhancedVideo {
                    if let enhanced_video_id = enhancedVideo.enhanced_video_id {
                        if enhanced_video_id == self.asset.asset!.localIdentifier {
                            self.enhancedLabel.isHidden = false
                        }
                    }
                }
                
                
            } else {
                self.enhancedLabel.isHidden = true
                self.durationLabel.isHidden = false
                let seconds = self.asset.audio!.duration
                let hours =  seconds / 3600;
                var remainder = seconds - hours * 3600;
                let mins = remainder / 60;
                remainder = remainder - mins * 60;
                self.durationLabel.text = "\(String(format: "%02d", hours)):\(String(format: "%02d", mins)):\(String(format: "%02d", remainder))"

                self.thumbnail.image = #imageLiteral(resourceName: "audio_image")

            }
        }
    }
    
}
