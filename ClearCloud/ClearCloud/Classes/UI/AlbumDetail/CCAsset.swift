//
//  CCAsset.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/18/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import Photos

class CCAsset: NSObject {

    enum AssetType {
        case video
        case audio
        case add
    }

    var name:String? = nil
    var asset:PHAsset? = nil
    var type:AssetType? = nil
    var audio:CCAudio? = nil

}
