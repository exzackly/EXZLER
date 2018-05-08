//
//  SymbolTable.swift
//  EXZLER
//
//  Created by EXZACKLY on 3/29/18.
//

import Foundation

enum CheckType {
    case initialize
    case use
}

typealias ScopeType = (type: VarType, lineNumber: Int, isInitialized: Bool, isUsed: Bool, idIndex: Int?)

class SymbolTable: Tree<[String: ScopeType]> {
    
    override var description: String {
        var builder = "Symbol Table\n"
        for (i, scope) in expandSymbolTable(node: self.root.children[0]).enumerated() {
            builder += "Scope \(i)\n"
            for variable in scope {
                builder += variable
            }
        }
        return builder == "Symbol Table\n" ? "Symbol Table\n empty\n" : builder
    }
    
    func expandSymbolTable(node: TreeNode<[String: ScopeType]>, depth: Int = 0) -> [[String]] {
        var expanded = [[String]]()
        var builder = [String]()
        for (variable, data) in node.data.sorted(by: { $0.value.lineNumber < $1.value.lineNumber }) {
            builder.append(" Variable [ \(variable) ] with type [ \(data.type) ] declared on line \(data.lineNumber)\n")
        }
        if builder.count > 0 {
            expanded.append(builder)
        }
        for child in node.children {
            expanded += expandSymbolTable(node: child, depth: depth+1)
        }
        return expanded
    }
    
    func addCurrent(key: String, value: ScopeType) -> Bool {
        guard current.data[key] == nil else {
            return false
        }
        current.data[key] = value
        return true
    }
    
    func checkCurrent(key: String, checkType: CheckType, node: TreeNode<[String: ScopeType]>? = nil) -> (type: VarType, idIndex: Int)? {
        let node = node ?? current
        if checkType == .initialize {
            node.data[key]?.isInitialized = true
        } else {
            node.data[key]?.isUsed = true
        }
        if node.data[key] != nil {
            return (node.data[key]!.type, node.data[key]!.idIndex!)
        } else {
            return node.parent != nil ? checkCurrent(key: key, checkType: checkType, node: node.parent) : nil
        }
    }

    func check(node: TreeNode<[String: ScopeType]>? = nil) -> (Int, [String]) {
        var warningCount = 0
        var warningMessages = [String]()
        let node = node ?? root
        
        for (variable, data) in node.data.sorted(by: { $0.key < $1.key }) {
            if !data.isInitialized {
                warningCount += 1
                warningMessages.append("Variable [ \(variable) ] declared on line \(data.lineNumber) was not initialized")
            } else if !data.isUsed {
                warningCount += 1
                warningMessages.append("Variable [ \(variable) ] declared on line \(data.lineNumber) has been initialized but was not used")
            }
        }
        for child in node.children {
            let (newWarningCount, newWarningMessages) = check(node: child)
            warningCount += newWarningCount
            warningMessages += newWarningMessages
        }
        
        return (warningCount, warningMessages)
    }
    
}
