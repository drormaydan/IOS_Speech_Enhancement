//
//  CCAudio.swift
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
