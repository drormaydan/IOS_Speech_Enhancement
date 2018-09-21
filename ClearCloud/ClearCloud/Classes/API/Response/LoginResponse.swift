//
//  LoginResponse.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/20/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

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
