//
//  main.swift
//  EXZLER
//
//  Created by EXZACKLY on 1/25/18.
//

import Foundation

let INPUT_FILENAME = CommandLine.arguments[1]

let program = parseSourceFromFile(filename: INPUT_FILENAME)

//lex(program: program, verbose: true)

//lex(program: "{ \"test custom program here\" }", verbose: true)

lex(program: "{ \"test custom /* this should be keyed out */program here\" }$", verbose: true)
