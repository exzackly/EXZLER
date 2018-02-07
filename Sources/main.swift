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
//let TEST_PARSING_FLAG = "-p"
//let TEST_SEMANTIC_ANALYSIS_FLAG = "-s"
//let TEST_CODE_GEN_FLAG = "-c"
//let TEST_EXZLER = "-t"

if CommandLine.arguments.contains(TEST_LEXING_FLAG) {
    testLexing()
}

guard let filenameIndex = CommandLine.arguments.index(of: FILENAME_FLAG),
    CommandLine.arguments.count > filenameIndex else {
    exit(0) // Filename not specified
}

let inputFilename = CommandLine.arguments[filenameIndex+1]
let isVerboseMode = CommandLine.arguments.contains(VERBOSE_FLAG)

guard let program = parseSourceFromFile(filename: inputFilename) else {
    exit(1) // Exit code 1 indicates input file not found
}

guard let tokens = lex(program: program, verbose: isVerboseMode) else {
    exit(2) // Exit code 2 indicates lex error
}
