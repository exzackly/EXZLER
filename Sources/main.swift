//
//  main.swift
//  EXZLER
//
//  Created by EXZACKLY on 1/25/18.
//

import Foundation

let FILENAME_FLAG = "-f"
let VERBOSE_FLAG = "-v"
let TEST_LEXING_FLAG = "-l"
let TEST_PARSING_FLAG = "-p"
//let TEST_SEMANTIC_ANALYSIS_FLAG = "-s"
//let TEST_CODE_GEN_FLAG = "-c"
//let TEST_EXZLER = "-t"

let flagTestPairs: [(String, Tester.Tests)] = [
    (TEST_LEXING_FLAG, .lexing),
    (TEST_PARSING_FLAG, .parsing)
]

let tests = flagTestPairs.filter{ CommandLine.arguments.contains($0.0) }.map { $0.1 }

Tester.test(tests)

guard let filenameFlagIndex = CommandLine.arguments.index(of: FILENAME_FLAG),
    CommandLine.arguments.count > filenameFlagIndex+1 else {
    exit(0) // Filename not specified
}

let inputFilename = CommandLine.arguments[filenameFlagIndex+1]
let isVerboseMode = CommandLine.arguments.contains(VERBOSE_FLAG)

guard let program = read(filename: inputFilename) else {
    exit(1) // Exit code 1 indicates input file not found
}

if isVerboseMode {
    print(program + "\n")
}

guard let tokens = Lexer.lex(program: program, verbose: isVerboseMode) else {
    exit(2) // Exit code 2 indicates lex error
}

guard let AST = Parser.parse(tokens: tokens, verbose: isVerboseMode) else {
    exit(3) // Exit code 3 indicates parse error
}

semanticAnalyze(tokens: tokens)
