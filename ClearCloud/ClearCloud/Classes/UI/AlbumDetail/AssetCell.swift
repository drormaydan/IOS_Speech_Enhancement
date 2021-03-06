//
//  AssetCell.swift
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
import Photos
import RealmSwift

class AssetCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    var asset:CCAsset!
    var owner:AlbumDetailVC!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var enhancedLabel: UIImageView!
    @IBOutlet weak var checkmark: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.durationLabel.backgroundColor = UIColor.init(hex: "#000000", alpha: 0.3)
        self.timeLabel.backgroundColor = UIColor.init(hex: "#000000", alpha: 0.3)
    }
    
    func populate() {
        
        if (self.asset.type == .add) {
            self.timeLabel.isHidden = true
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
                self.timeLabel.isHidden = true
                self.durationLabel.isHidden = false
                let manager = PHImageManager.default()
                let option = PHImageRequestOptions()
                var thumb = UIImage()
                option.isSynchronous = true
                manager.requestImage(for: self.asset.asset!, targetSize: CGSize(width: self.thumbnail.frame.width, height: self.thumbnail.frame.height), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
                    if let result = result {
                        thumb = result
                    }
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
                self.timeLabel.isHidden = false
                self.enhancedLabel.isHidden = true
                self.durationLabel.isHidden = false
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy hh:mm a"
                self.timeLabel.text = dateFormatter.string(from: self.asset.audio!.local_time_start!)
                
                let seconds = self.asset.audio!.duration
                let hours =  seconds / 3600;
                var remainder = seconds - hours * 3600;
                let mins = remainder / 60;
                remainder = remainder - mins * 60;
                self.durationLabel.text = "\(String(format: "%02d", hours)):\(String(format: "%02d", mins)):\(String(format: "%02d", remainder))"

                self.thumbnail.image = #imageLiteral(resourceName: "audio_image")

                if self.asset.audio!.enhanced_audio_path != nil {
                    self.enhancedLabel.isHidden = false
                }
            }
        }
    }
    
}
