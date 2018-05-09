//
//  EXZLER.swift
//  EXZLER
//
//  Created by EXZACKLY on 4/1/18.
//

import Foundation

class EXZLER {
    
    private static var messenger: Messenger!
    
    static func compile(input: String, verbose isVerbose: Bool = false, emit: ((String, String, String) -> ())? = nil) {
        let emit = emit ?? { (prefix, delimiter, message) in print(prefix+delimiter+message) }
        messenger = Messenger(prefix: "EXZLER", verbose: isVerbose, emit: emit)
        // Strip comments while maintaining newlines
        var programs = input
        while true {
            guard let commentRange = programs.range(of: "\\/\\*(.|\\s)*?\\*\\/", options: .regularExpression) else {
                break
            }
            let newlineCount = String(programs[commentRange]).matches(forPattern: "\n").count
            programs.replaceSubrange(commentRange, with: String(repeating: "\n", count: newlineCount))
        }
        
        programs = programs.replacingOccurrences(of: "$", with: "$`")
        
        for (i, program) in programs.split(separator: "`").enumerated() {
            if program.trimmingCharacters(in: .whitespacesAndNewlines) == "" { continue }
            messenger.message(type: .system, message: "Program \(i)\n\(program)\n")
            guard let tokens = Lexer.lex(program: String(program), verbose: isVerbose, emit: emit),
                let AST = Parser.parse(tokens: tokens, verbose: isVerbose, emit: emit),
                SemanticAnalyzer.analyze(AST: AST, verbose: isVerbose, emit: emit) != nil,
                let code = CodeGenerator.generate(AST: AST, verbose: isVerbose, emit: emit) else {
                    continue // Continue processing other programs
            }
            // Print result regardless of verbose
            messenger.message(type: .system, message: code, override: true)
        }
    }
    
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

let BOOLOP_NODE = "Boolop"
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
