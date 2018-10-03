//
//  OktaUserProfile.swift
//  ClearCloud
//
//  Created by Boris Katok on 10/3/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import ObjectMapper

class OktaUserProfile: NSObject, Mappable {

    var firstName: String?
    var lastName: String?
    
    override init() {}
    
    // MARK: ServerObject
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        firstName <- map["firstName"]
        lastName <- map["lastName"]
    }

}
