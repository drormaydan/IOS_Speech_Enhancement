//
//  AssetCell.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/18/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import Photos

class AssetCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    var asset:CCAsset!
    @IBOutlet weak var durationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.durationLabel.backgroundColor = UIColor.init(hex: "#000000", alpha: 0.3)
    }
    
    func populate() {
        
        if (self.asset.type == .add) {
            self.thumbnail.image = #imageLiteral(resourceName: "blue_plus")
            self.durationLabel.isHidden = true
        } else {
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
            
        }
    }
    
}
