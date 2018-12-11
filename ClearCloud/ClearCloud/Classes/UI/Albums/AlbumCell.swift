//
//  AlbumCell.swift
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
        if album.type == .video {
            numItems.text = "\(self.album.asset!.videosCount)"
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            let result:PHFetchResult<PHAsset> = PHAsset.fetchAssets(in: self.album.asset!, options: fetchOptions)
            if result.count > 0 {
                let first:PHAsset = result[0]
                
                let manager = PHImageManager.default()
                let option = PHImageRequestOptions()
                var thumb = UIImage()
                option.isSynchronous = true
                manager.requestImage(for: first, targetSize: CGSize(width: self.thumbnail.frame.width, height: self.thumbnail.frame.height), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
                    if let result = result {
                        thumb = result
                    }
                })
                self.thumbnail.image = thumb
            } else {
                self.thumbnail.image = nil
            }
        } else {
            self.thumbnail.image = #imageLiteral(resourceName: "audio_image")
            let realm = try! Realm()
            let tmp = realm.objects(CCAudio.self).sorted(byKeyPath: "local_time_start", ascending: false)
            numItems.text = "\(tmp.count)"
        }
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
