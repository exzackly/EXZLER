//
//  Lexer.swift
//  EXZLER
//
//  Created by EXZACKLY on 1/28/18.
//

import Foundation

class Lexer {
    
    private typealias SymbolType = (regularExpression: String, tokenType: TokenType)
    
    private static let symbols: [SymbolType] = [
        ("\\{", .leftCurlyBrace),   // {
        ("\\}", .rightCurlyBrace),  // }
        ("\\(", .leftParenthesis),  // (
        ("\\)", .rightParenthesis), // )
        ("\\+", .addition),         // +
        ("==", .equality),          // ==
        ("!=", .inequality),        // !=
        ("=", .assignment),         // =
        ("if", .if),                // if
        ("while", .while),          // while
        ("print", .print),          // print
        ("true", .boolean),         // true
        ("false", .boolean),        // false
        ("int", .type),             // int
        ("boolean", .type),         // boolean
        ("string", .type),          // string
        ("[0-9]", .digit),          // digit
        ("\"[ a-z]*\"", .string),   // char list
        ("[a-z]", .id),             // id
        ("\\s", .space),            // space
        ("\\$", .EOP),              // end of program
        ("\".*\"", .invalid),       // invalid char list
        (".+?", .invalid)           // catch all other invalid
    ]
    
    private static let coalescedRegularExpression = symbols.reduce(""){ $0 == "" ? "(\($1.regularExpression))" : $0 + "|" + "(\($1.regularExpression))" }
    
    private static var messenger: Messenger!
    
    static func lex(program: String, verbose isVerbose: Bool = false, emit: @escaping (String, String, String) -> ()) -> [Token]? {
        messenger = Messenger(prefix: "LEXER", verbose: isVerbose, emit: emit)
        
        var tokens: [Token] = []
        var warningCount = 0
        
        // Break input into lines to provide line numbers for warnings and errors
        let programLines = program.components(separatedBy: "\n")
        
        // Process program line by line
        for (lineNumber, programLine) in programLines.enumerated() {
            let tokenMatches = programLine.matches(forPattern: coalescedRegularExpression)
            
            let extractedMatches = extract(matches: tokenMatches, from: programLine)
            
            for match in extractedMatches {
                if match.tokenType == .invalid { // Catch errors
                    messenger.message(type: .error, message: "Invalid token [\(match.substring)] on line \(lineNumber+1)\nLexing failed with \(warningCount) warning(s) and 1 error(s)") // local lineNumber 0-indexed
                    return nil
                } else if match.tokenType == .space { // Skip whitespace
                    continue
                }
                let newToken = Token(type: match.tokenType, data: match.substring, lineNumber: lineNumber+1) // local lineNumber 0-indexed
                messenger.message(type: .success, message: newToken.description)
                tokens.append(newToken)
            }
        }
        
        // Program needs at least 1 token
        guard tokens.count > 0 else {
            messenger.message(type: .error, message: "Input did not generate any valid tokens\nLexing failed with \(warningCount) warning(s) and 1 error(s)")
            return nil
        }
        
        messenger.message(type: .system, message: "Found \(tokens.count) tokens")
        
        // Check if program ended with EOP [ $ ]. Issue warning and add if not
        if tokens.last?.type != .EOP {
            let lastLine = tokens.last?.lineNumber ?? 0 // Line to add EOP [ $ ]
            let EOPToken = Token(type: .EOP, data: "$", lineNumber: lastLine)
            tokens.append(EOPToken)
            warningCount += 1
            messenger.message(type: .warning, message: "EOP [ $ ] not found. Adding to end of file on line \(lastLine)")
        }
        
        // Print result regardless of verbose
        messenger.message(type: .system, message: "Lexing completed with \(warningCount) warning(s) and 0 error(s)\n", override: true)
        
        return tokens
    }
    
    private static func extract(matches: [NSTextCheckingResult], from program: String) -> [(substring: String, tokenType: TokenType)] {
        var extractedMatches: [(substring: String, tokenType: TokenType)] = []
        outer: for match in matches {
            let matchRanges = (0..<match.numberOfRanges).map{ match.range(at: $0) } // Extract all ranges (capture groups)
            for (index, range) in matchRanges.enumerated().reversed() { // Iterate through ranges and grab last capture group
                if range.location != NSNotFound {
                    let substring = String(program[Range(match.range, in: program)!])
                    let tokenType = symbols[index-1].tokenType // Symbols 0-indexed
                    extractedMatches.append((substring: substring, tokenType: tokenType))
                    continue outer
                }
            }
        }
        return extractedMatches
    }
    
}
