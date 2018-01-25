//
//  main.swift
//  EXZLER
//
//  Created by EXZACKLY on 1/25/18.
//

import Foundation

let INPUT_FILENAME = CommandLine.arguments[1]

guard let fileContents = readFile(filename: INPUT_FILENAME) else {
    print(INPUT_FILENAME + " could not be found")
    exit(1) // Exit code 1 indicates input file not found
}

print(fileContents)
