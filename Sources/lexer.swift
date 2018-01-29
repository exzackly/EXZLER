//
//  lexer.swift
//  EXZLER
//
//  Created by EXZACKLY on 1/28/18.
//

import Foundation

enum TokenType: String {
    case leftCurlyBrace   = "left curly brace"
    case rightCurlyBrace  = "right curly brace"
    case leftParenthesis  = "left parenthesis"
    case rightParenthesis = "right parenthesis"
    case addition         = "addition"
    case equality         = "equality"
    case inequality       = "inequality"
    case assignment       = "assignment"
    case `if`             = "if"
    case `while`          = "while"
    case print            = "print"
    case type             = "type"    // int, boolean, string
    case boolean          = "boolean" // true, false
    case digit            = "digit"
    case string           = "string"
    case id               = "id"
    case comment          = "comment"
    case space            = "space"
    case EOP              = "EOP"
    case invalid          = "invalid"
}

class Token: CustomStringConvertible {
    let type: TokenType
    let data: String
    let lineNumber: Int
    
    var description: String {
        return "\(type.rawValue) [ \(data) ] on line \(lineNumber)"
    }
    
    init(type: TokenType, data: String, lineNumber: Int) {
        self.type = type
        self.data = data
        self.lineNumber = lineNumber
    }
}
