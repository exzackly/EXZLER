//
//  main.swift
//  EXZLER
//
//  Created by EXZACKLY on 1/25/18.
//

import Foundation

let FILENAME_FLAG = "-f"
let VERBOSE_FLAG = "-v"
let TEST_EXZLER = "-t"

if CommandLine.arguments.contains(TEST_EXZLER) {
    Tester.testEXZLER()
}

guard let filenameFlagIndex = CommandLine.arguments.index(of: FILENAME_FLAG),
    CommandLine.arguments.count > filenameFlagIndex+1 else {
        exit(0) // Filename not specified
}

let inputFilename = CommandLine.arguments[filenameFlagIndex+1]
let isVerboseMode = CommandLine.arguments.contains(VERBOSE_FLAG)

guard var programs = read(filename: inputFilename) else {
    exit(1) // Exit code 1 indicates input file not found
}

EXZLER.compile(input: programs, verbose: isVerboseMode)
