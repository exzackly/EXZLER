//
//  main.swift
//  EXZLER
//
//  Created by EXZACKLY on 1/25/18.
//

import Foundation

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

let FILENAME_FLAG = "-f"
let VERBOSE_FLAG = "-v"
let TEST_LEXING_FLAG = "-l"
let TEST_PARSING_FLAG = "-p"
//let TEST_SEMANTIC_ANALYSIS_FLAG = "-s"
//let TEST_CODE_GEN_FLAG = "-c"
//let TEST_EXZLER = "-t"

if CommandLine.arguments.contains(TEST_LEXING_FLAG) {
    testLexing()
}

if CommandLine.arguments.contains(TEST_PARSING_FLAG) {
    testParsing()
}

guard let filenameFlagIndex = CommandLine.arguments.index(of: FILENAME_FLAG),
    CommandLine.arguments.count > filenameFlagIndex+1 else {
    exit(0) // Filename not specified
}

let inputFilename = CommandLine.arguments[filenameFlagIndex+1]
let isVerboseMode = CommandLine.arguments.contains(VERBOSE_FLAG)

guard let program = parseSourceFromFile(filename: inputFilename) else {
    exit(1) // Exit code 1 indicates input file not found
}

if isVerboseMode {
    print(program + "\n")
}

guard let tokens = lex(program: program, verbose: isVerboseMode) else {
    exit(2) // Exit code 2 indicates lex error
}

guard let CST = parse(tokens: tokens, verbose: isVerboseMode) else {
    exit(3) // Exit code 3 indicates parse error
}
