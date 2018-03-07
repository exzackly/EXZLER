//
//  lexer.swift
//  EXZLER
//
//  Created by EXZACKLY on 1/28/18.
//

import Foundation

typealias SymbolType = (regularExpression: String, tokenType: TokenType)

let symbols: [SymbolType] = [
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
    ("\".*\"", .invalid)        // invalid char list
]

let coalescedRegularExpression = symbols.reduce(""){ $0 == "" ? "(\($1.regularExpression))" : $0 + "|" + "(\($1.regularExpression))" }

func lex(program: String, verbose: Bool = false) -> [Token]? {
    var tokens: [Token] = []
    var warningCount = 0
    
    // Strip comments. Need to do here in case comment in string (char list)
    let program = program.replacingOccurrences(of: "\\/\\*(.|\\s)*?\\*\\/", with: "", options: .regularExpression)
    
    // Break input into lines to provide line numbers for warnings and errors
    let programLines = program.components(separatedBy: "\n")
    
    // Process program line by line
    for (lineNumber, programLine) in programLines.enumerated() {
        let tokenMatches = programLine.matches(forPattern: coalescedRegularExpression)
        
        let extractedMatches = extract(matches: tokenMatches, from: programLine)
        
        for match in extractedMatches {
            if match.tokenType == .invalid { // Catch errors
                print("ERROR: Invalid token [\(match.substring)] on line \(lineNumber+1)") // local lineNumber 0-indexed
                print("Lexing failed with \(warningCount) warning(s) and 1 error(s)")
                return nil
            } else if match.tokenType == .space { // Skip whitespace
                continue
            }
            let newToken = Token(type: match.tokenType, data: match.substring, lineNumber: lineNumber+1) // local lineNumber 0-indexed
            if verbose {
                print("LEXER -> \(newToken)")
            }
            tokens.append(newToken)
        }
        print()
    }
    
    // Program needs at least 1 token
    guard tokens.count > 0 else {
        print("ERROR: Input did not generate any valid tokens")
        return nil
    }
    
    if verbose {
        print("Found \(tokens.count) tokens")
    }
    
    // Check if program ended with EOP [ $ ]. Issue warning and add if not
    if tokens.last?.type != .EOP {
        let lastLine = tokens.last?.lineNumber ?? 0 // Line to add EOP [ $ ]
        let EOPToken = Token(type: .EOP, data: "$", lineNumber: lastLine)
        tokens.append(EOPToken)
        warningCount += 1
        print("WARNING: EOP [ $ ] not found. Adding to end of file on line \(lastLine)")
    }
    
    // Print result regardless of verbose
    print("Lexing completed with \(warningCount) warning(s) and 0 error(s)\n")
    
    return tokens
}

func extract(matches: [NSTextCheckingResult], from program: String) -> [(substring: String, tokenType: TokenType)] {
    var currentLocation = 0 // Used to ensure that ranges are contiguous. Non-matched section means invalid token found
    var extractedMatches: [(substring: String, tokenType: TokenType)] = []
    
    outer: for match in matches {
        let matchRanges = (0..<match.numberOfRanges).map{ match.range(at: $0) } // Extract all ranges (capture groups)
        for (index, range) in matchRanges.enumerated().reversed() { // Iterate through ranges and grab last capture group
            if range.location != NSNotFound {
                guard range.location == currentLocation else { // Non-matched section found; invalid token
                    let errorRange = NSRange(location: currentLocation, length: 1)
                    let errorData = String(program[Range(errorRange, in: program)!])
                    return [(errorData, .invalid)]
                }
                currentLocation += range.length
                let substring = String(program[Range(match.range, in: program)!])
                let tokenType = symbols[index-1].tokenType // Symbols 0-indexed
                extractedMatches.append((substring: substring, tokenType: tokenType))
                continue outer
            }
        }
    }
    return extractedMatches
}
