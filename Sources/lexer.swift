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

typealias SymbolType = (regularExpression: String, tokenType: TokenType)

let symbols: [SymbolType] = [
    //TODO: Fix names
    ("\\{", .leftCurlyBrace),      // {
    ("\\}", .rightCurlyBrace),     // }
    ("\\(", .leftParenthesis),     // (
    ("\\)", .rightParenthesis),    // )
    ("\\+", .addition),            // +
    ("==", .equality),             // ==
    ("!=", .inequality),           // !=
    ("=", .assignment),            // =
    ("if", .if),                   // if
    ("while", .while),             // while
    ("print", .print),             // print
    ("true", .boolean),            // true
    ("false", .boolean),           // false
    ("int", .type),                // int
    ("boolean", .type),            // boolean
    ("string", .type),             // string
    ("[0-9]", .digit),             // digit
    ("\"[ a-z]*\"", .string),      // char list
    ("[a-z]", .id),                // id
    ("\\/\\*.*?\\*\\/", .comment), // comment
    ("\\s", .space),               // space
    ("\\$", .EOP)                  // end of program
]

let coalescedRegularExpression = symbols.reduce(""){ $0 == "" ? "(\($1.regularExpression))" : $0 + "|" + "(\($1.regularExpression))" }

func lex(program: String) {
    print(program)
    
    var tokens: [Token] = []
    
    // Break input into lines to provide line numbers for warnings and errors
    let programLines = program.components(separatedBy: "\n")
    
    // Process program line by line
    for (lineNumber, programLine) in programLines.enumerated() {
        let tokenMatches = programLine.matches(forPattern: coalescedRegularExpression)
        
        let extractedMatches = extract(matches: tokenMatches, from: programLine)
        
        guard extractedMatches.first?.tokenType != .invalid else {
            print("ERROR: Invalid token [\(extractedMatches[0].substring)] on line \(lineNumber+1)") // local lineNumber 0-indexed
            exit(2) // Exit code 2 indicates lex error
        }
        
        for match in extractedMatches {
            if match.tokenType == .comment || match.tokenType == .space { // Skip comments and whitespace
                continue
            }
            let newToken = Token(type: match.tokenType, data: match.substring, lineNumber: lineNumber+1) // local lineNumber 0-indexed
            tokens.append(newToken)
        }

    }
    
    print("Found \(tokens.count) tokens")
    for token in tokens {
        print("LEXER -> \(token)")
    }
    
    // Check if program ended with EOP [ $ ]. Issue warning and add if not
    if tokens.last?.type != .EOP {
        let lastLine = tokens.last?.lineNumber ?? 0 // Line to add EOP [ $ ]
        let EOPToken = Token(type: .EOP, data: "$", lineNumber: lastLine)
        tokens.append(EOPToken)
        print("WARNING: EOP [ $ ] not found. Adding to end of file on line \(lastLine)")
    }
}

func extract(matches: [NSTextCheckingResult], from program: String) -> [(substring: String, tokenType: TokenType)] {
    var currentLocation = 0 //TODO: COMMENT
    var extractedMatches: [(substring: String, tokenType: TokenType)] = []
    
    //TODO: comment
    outer: for match in matches {
        let matchRanges = (0..<match.numberOfRanges).map{ match.range(at: $0) }
        for (index, range) in matchRanges.enumerated().reversed() {
            if range.location != NSNotFound {
                guard range.location == currentLocation else {
                    let errorRange = NSRange(location: currentLocation, length: 1)
                    return [(String(program[Range(errorRange, in: program)!]), .invalid)]
                }
                currentLocation += range.length
                let substring = String(program[Range(match.range, in: program)!])
                let tokenType = symbols[index-1].tokenType
                extractedMatches.append((substring: substring, tokenType: tokenType))
                continue outer
            }
        }
    }
    return extractedMatches
}
