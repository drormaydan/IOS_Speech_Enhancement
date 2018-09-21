//
//  ServerError.swift
//  ClearCloud
//
//  Created by Boris Katok on 9/20/18.
//  Copyright © 2018 Boris Katok. All rights reserved.
//

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

