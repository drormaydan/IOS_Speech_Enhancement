//
//  Album.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/18/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import Photos

class Album: NSObject {

    enum AlbumType {
        case video
        case audio
    }

    var name:String? = nil
    var asset:PHAssetCollection? = nil
    var type:AlbumType? = nil
    
}
