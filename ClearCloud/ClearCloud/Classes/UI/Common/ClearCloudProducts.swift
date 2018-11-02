//
//  ClearCloudProducts.swift
//  ClearCloud
//
//  Created by Boris Katok on 10/30/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

import Foundation

public struct ClearCloudProducts {
    
    public static let MoreMoney = "com.babblelabs.clearcloud.minutes_5"
    
    private static let productIdentifiers: Set<ProductIdentifier> = [ClearCloudProducts.MoreMoney]
    
    public static let store = IAPHelper(productIds: ClearCloudProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}

