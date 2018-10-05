//
//  CCAudio.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/18/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import UIKit
import RealmSwift

class CCAudio: Object {
    
    @objc dynamic var unique_id:String? = nil
    @objc dynamic var name: String? = nil
    @objc dynamic var enhanced_name: String? = nil
    @objc dynamic var audio_size: Double = 0.0
    @objc dynamic var duration: Int = 0
    @objc dynamic var enhanced_date:Date?
    @objc dynamic var local_time_start:Date?
    @objc dynamic var local_audio_path: String? = nil
    @objc dynamic var enhanced_audio_path: String? = nil

}
