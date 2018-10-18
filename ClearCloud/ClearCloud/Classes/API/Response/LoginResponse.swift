//
//  LoginResponse.swift
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

import ObjectMapper

class LoginResponse: NSObject, Mappable {
    // MARK: Properties
    
    var expires_in: Int?
    var auth_token: String?
    var token_type: String?
    
    override init() {}
    
    // MARK: ServerObject
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        expires_in <- map["expires_in"]
        auth_token <- map["auth_token"]
        token_type <- map["token_type"]
    }

}
