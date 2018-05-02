//
//  EXZLER.swift
//  EXZLER
//
//  Created by EXZACKLY on 4/1/18.
//

import Foundation

class EXZLER {
    
}

enum TokenType: String {
    case leftCurlyBrace   = "{"
    case rightCurlyBrace  = "}"
    case leftParenthesis  = "("
    case rightParenthesis = ")"
    case addition         = "+"
    case equality         = "=="
    case inequality       = "!="
    case assignment       = "="
    case `if`             = "if"
    case `while`          = "while"
    case print            = "print"
    case type             = "type"    // int, boolean, string
    case boolean          = "boolean" // true, false
    case digit            = "digit"
    case string           = "string"
    case id               = "id"
    case space            = "space"
    case EOP              = "EOP"
    case invalid          = "invalid"
}

enum VarType: String {
    case int = "int"
    case boolean = "boolean"
    case string = "string"
}

let TokenTypeToDescription: [TokenType : String] = [
    .leftCurlyBrace   : "left curly brace",
    .rightCurlyBrace  : "right curly brace",
    .leftParenthesis  : "left parenthesis",
    .rightParenthesis : "right parenthesis",
    .addition         : "addition",
    .equality         : "equality",
    .inequality       : "inequality",
    .assignment       : "assignment",
    .if               : "if",
    .while            : "while",
    .print            : "print",
    .type             : "type",    // int, boolean, string
    .boolean          : "boolean", // true, false
    .digit            : "digit",
    .string           : "string",
    .id               : "id",
    .space            : "space",
    .EOP              : "EOP",
    .invalid          : "invalid"
]

let ADDITION_NODE = "Addition"
let TRUE_NODE = "true"
let FALSE_NODE = "false"
let QUOTE_NODE: Character = "\""
let EQUALITY_NODE = "Equality"
let INEQUALITY_NODE = "Inequality"

class Token: CustomStringConvertible {
    
    let type: TokenType
    let data: String
    let lineNumber: Int
    
    var description: String {
        return "\(TokenTypeToDescription[type] ?? "") [ \(data) ] on line \(lineNumber)"
    }
    
    init(type: TokenType, data: String, lineNumber: Int) {
        self.type = type
        self.data = data
        self.lineNumber = lineNumber
    }
    
    init(type: TokenType, data: String) {
        self.type = type
        self.data = data
        self.lineNumber = 0
    }
    
}
