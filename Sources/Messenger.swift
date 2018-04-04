//
//  Messenger.swift
//  EXZLER
//
//  Created by EXZACKLY on 4/3/18.
//

import Foundation

class Messenger {
    
    enum MessageType {
        case system
        case success
        case warning
        case error
    }
    
    private let prefix: String
    private var hasPrintedError = false
    
    var verbose = false
    var emit: (String) -> () = { message in print(message) }
    
    init(prefix: String) {
        self.prefix = prefix
    }
    
    func message(type: MessageType, message: String, override: Bool = false) {
        var prefix = self.prefix
        switch type {
        case .system:
            if !verbose && !override { return }
            prefix = ""
        case .success:
            if !verbose && !override { return }
        case .warning:
            prefix = "WARNING: "
        case .error:
            if hasPrintedError { return }
            hasPrintedError = true
            prefix = "ERROR: "
        }
        emit(prefix + message)
    }
    
}
