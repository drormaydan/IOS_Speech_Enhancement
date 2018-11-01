//
//  AppleReceiptRequest.swift
//  ClearCloud
//
//  Created by Boris Katok on 10/31/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import ObjectMapper

class AppleReceiptRequest: NSObject, Mappable {
    // MARK: Properties
    var receiptdata: String?
    
    override init() {}
    
    // MARK: ServerObject
    
    public required init?(map: Map) {}
    
    public func mapping(map: Map) {
        receiptdata <- map["receipt-data"]
    }
    
}

