//
//  UserResponse.swift
//  ClearCloud
//
//  Created by Boris Katok on 10/3/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import ObjectMapper

class UserResponse: NSObject, Mappable {

    var profile: OktaUserProfile?
    var id: String?
    var status: String?
    
    override init() {}
    
    // MARK: ServerObject
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        id <- map["id"]
        status <- map["status"]
        profile <- map["profile"]
    }
}
