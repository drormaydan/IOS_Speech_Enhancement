//
//  EntitlementsResponse.swift
//  ClearCloud
//
//  Created by Boris Katok on 11/1/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import ObjectMapper

class EntitlementsResponse: NSObject, Mappable {

    var unbilledUsageInCents: Int?
    var customerDollarLimit: Int?
    var accountListingState: String?
    
    override init() {}
    
    // MARK: ServerObject
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        unbilledUsageInCents <- map["unbilledUsageInCents"]
        customerDollarLimit <- map["customerDollarLimit"]
        accountListingState <- map["accountListingState"]
    }

}
