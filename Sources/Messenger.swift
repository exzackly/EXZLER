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
    
    private let verbose: Bool
    private let emit: (String, String, String) -> ()
    
    init(prefix: String, verbose isVerbose: Bool, emit: @escaping (String, String, String) -> ()) {
        self.prefix = prefix
        self.verbose = isVerbose
        self.emit = emit
    }
    
    func message(type: MessageType, message: String, override: Bool = false) {
        var prefix = self.prefix
        var delimiter = ""
        switch type {
        case .system:
            if !verbose && !override { return }
            prefix = ""
        case .success:
            if !verbose && !override { return }
            delimiter = " -> "
        case .warning:
            prefix = "WARNING: "
        case .error:
            if hasPrintedError { return }
            hasPrintedError = true
            prefix = "ERROR: "
        }
        emit(prefix, delimiter, message)
    }
    
}
