//
//  ServerError.swift
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

class ServerError: NSObject {
    
    static let defaultError: ServerError = ServerError(WithMessage: "Sorry, an error occurred. Please, try again.")
    static let noInternet: ServerError = ServerError(WithMessage: "Please check your network and try again.")
    static let readingFile: ServerError = ServerError(WithMessage: "Error reading file.")
    static let writingFile: ServerError = ServerError(WithMessage: "Error writing file.")

    fileprivate var message: String?
    
    // MARK: Public functions
    
    init(WithMessage message: String) {
        self.message = message
    }
    
    func getMessage() -> String? {
        return message
    }
    
}

