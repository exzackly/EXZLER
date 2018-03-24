//
//  readFromFile.swift
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

func read(filename: String) -> String? {
    guard let fileContents = readFromFile(filename: filename) else {
        print(filename + " could not be found")
        return nil
    }
    return fileContents.trimmingCharacters(in: .whitespacesAndNewlines)
}
