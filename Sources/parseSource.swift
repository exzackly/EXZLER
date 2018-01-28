//
//  parseSource.swift
//  EXZLER
//
//  Created by EXZACKLY on 1/25/18.
//

import Foundation

private func readFromFile(filename: String) -> String? {
    let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let fileURL = URL(fileURLWithPath: filename, relativeTo: currentDirectoryURL)
    
    if let fileContents = try? String(contentsOf: fileURL, encoding: .utf8) {
        return fileContents
    } else {
        return nil
    }
}

func parseSourceFromFile(filename: String) -> String {
    guard let fileContents = readFromFile(filename: INPUT_FILENAME) else {
        print(INPUT_FILENAME + " could not be found")
        exit(1) // Exit code 1 indicates input file not found
    }
    return fileContents.trimmingCharacters(in: .whitespacesAndNewlines)
}
