//
//  AlbumCell.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/18/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import Photos

class AlbumCell: UICollectionViewCell {
    
    @IBOutlet weak var albumName: UILabel!
    @IBOutlet weak var numItems: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!
    
    var album:Album!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func populate() {
        albumName.text = self.album.name
        numItems.text = "\(self.album.asset!.videosCount)"
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        let result:PHFetchResult<PHAsset> = PHAsset.fetchAssets(in: self.album.asset!, options: fetchOptions)
        let first:PHAsset = result[0]
        
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumb = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: first, targetSize: CGSize(width: self.thumbnail.frame.width, height: self.thumbnail.frame.height), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumb = result!
        })
        self.thumbnail.image = thumb

    }

}
extension PHAssetCollection {
    var videosCount: Int {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        let result = PHAsset.fetchAssets(in: self, options: fetchOptions)
        return result.count
    }
}
