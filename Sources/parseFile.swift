//
//  parseFile.swift
//  EXZLER
//
//  Created by EXZACKLY on 1/25/18.
//

import Foundation

func readFile(filename: String) -> String? {
    let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let fileURL = URL(fileURLWithPath: filename, relativeTo: currentDirectoryURL)
    
    if let fileContents = try? String(contentsOf: fileURL, encoding: .utf8) {
        return fileContents
    } else {
        return nil
    }
}
