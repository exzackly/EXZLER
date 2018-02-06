//
//  main.swift
//  EXZLER
//
//  Created by EXZACKLY on 1/25/18.
//

import Foundation

let INPUT_FILENAME = CommandLine.arguments[1]
let VERBOSE = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] == "-v" : false

let program = parseSourceFromFile(filename: INPUT_FILENAME)

//lex(program: program, verbose: VERBOSE)

//lex(program: "{ \"test custom program here\" }", verbose: VERBOSE)

lex(program: "{ print(\"int % f\"))))}", verbose: VERBOSE)
