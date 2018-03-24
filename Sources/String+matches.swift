//
//  String+matches.swift
//  EXZLER
//
//  Created by EXZACKLY on 2/2/18.
//

import Foundation

extension String {
    
    func matches(forPattern pattern: String) -> [NSTextCheckingResult] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) else {
            return []
        }
        return regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
    }
    
}

