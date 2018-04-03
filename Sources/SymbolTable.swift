//
//  SymbolTable.swift
//  EXZLER
//
//  Created by EXZACKLY on 3/29/18.
//

import Foundation

enum VarType: String {
    case int = "int"
    case boolean = "boolean"
    case string = "string"
}

enum CheckType {
    case initialize
    case use
}

typealias ScopeType = (type: VarType, lineNumber: Int, isInitialized: Bool, isUsed: Bool)

class SymbolTable: Tree<[String: ScopeType]> {
    
    override var description: String {
        return "Symbol Tree\n" + super.description
        
    }
    
    func addCurrent(key: String, value: ScopeType) -> Bool {
        guard current.data[key] == nil else {
            return false
        }
        current.data[key] = value
        return true
    }
    
    func checkCurrent(key: String, checkType: CheckType, node: TreeNode<[String: ScopeType]>? = nil) -> VarType? {
        let node = node ?? current
        if checkType == .initialize {
            node.data[key]?.isInitialized = true
        } else {
            node.data[key]?.isUsed = true
        }
        return node.data[key]?.type ?? (node.parent != nil ? checkCurrent(key: key, checkType: checkType, node: node.parent) : nil)
    }
    
}
