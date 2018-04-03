//
//  SemanticAnalyzer.swift
//  EXZLER
//
//  Created by EXZACKLY on 3/29/18.
//

import Foundation

extension TreeNode where T == ASTNode {
    
    var child: TreeNode<T> {
        return self.children[0]
    }
    var leftChild: TreeNode<T> {
        return self.children[0]
    }
    
    var rightChild: TreeNode<T> {
        return self.children[1]
    }
    var key: String {
        let blockMatch = self.data.name.matches(forPattern: "\\[ (.*?) \\]").first
        let braceMatch = self.data.name.matches(forPattern: "<(.*?)>").first
        let range = blockMatch?.range(at: 1) ?? braceMatch?.range(at: 1) ?? NSRange()
        return String(self.data.name[Range(range, in: self.data.name)!])
    }
    
}

class SemanticAnalyzer {
    
    private static let ADDITION_NODE = "Addition"
    private static let TRUE_NODE = "true"
    private static let FALSE_NODE = "false"
    private static let QUOTE_NODE: Character = "\""
    private static let EQUALITY_NODE = "Equality"
    private static let INEQUALITY_NODE = "Inequality"
    
    private enum MessageType {
        case success
        case error
    }
    
    typealias MessageData = (expecting: String, found: String, lineNumber: Int)
    
    private static func message(type: MessageType, data: MessageData? = nil, overrideMessage: String? = nil) {
        if data == nil && overrideMessage == nil { // data and overrideTemplate cannot both be nil
            return
        }
        switch type {
        case .success:
            if !verbose {
                return
            }
            let prefix = "SEMANTIC ANALYZER -> "
            let message = data != nil ? "Expecting [ \(data!.expecting) ] found [ \(data!.found) ] on line \(data!.lineNumber)" : overrideMessage!
            print(prefix + message)
        case .error:
            if hasPrintedError {
                return
            }
            hasPrintedError = true
            let prefix = "ERROR: "
            let message = data != nil ? "Expecting [ \(data!.expecting) ] found [ \(data!.found) ] on line \(data!.lineNumber)" : overrideMessage!
            print(prefix + message)
            print("Semantic analyzing completed with 0 warning(s) and 1 error(s)\n")
        }
    }
    
    private static var symbolTable = SymbolTable(data: [:])
    private static var verbose = false
    private static var hasPrintedError = false
    
    static func analyze(AST: Tree<ASTNode>, verbose isVerbose: Bool = false) -> SymbolTable? {
        symbolTable = SymbolTable(data: [:])
        verbose = isVerbose
        hasPrintedError = false
        
        guard checkBlock(node: AST.root.child.child) else { // Isolate main program block
            return nil
        }
        
        let warningCount = symbolTable.check()
        
        // Print result regardless of verbose
        print("Semantic analyzing completed with \(warningCount) warning(s) and 0 error(s)\n")
        
        if isVerbose {
            print("\(symbolTable)")
        }
        
        return symbolTable
    }
    
    private static let checkBlockNodeMap = [
        "PrintStatement" : checkPrint,
        "AssignmentStatement" : checkAssignment,
        "VarDecl" : checkVarDecl,
        "WhileStatement" : checkWhileAndIf,
        "IfStatement" : checkWhileAndIf,
        "Block" : checkBlock
    ]
    
    private static func checkBlock(node: TreeNode<ASTNode>) -> Bool {
        symbolTable.addChild(data: [:]) // Create new scope
        for child in node.children { // Check all children nodes
            let action = checkBlockNodeMap[child.key]! // Determine type of node
            guard action(child) else { // Assert node type
                return false
            }
        }
        symbolTable.endChild() // End of scope
        return true
    }
    
    
    private static func checkPrint(node: TreeNode<ASTNode>) -> Bool {
        guard checkExpr(node: node.child, expectedType: nil) != nil else {
            return false
        }
        return true
    }
    
    private static func checkExpr(node: TreeNode<ASTNode>, expectedType: VarType?) -> VarType? {
        var foundType: VarType? = nil
        if Int(node.key) != nil {                                                 // Expr ::== IntExpr; IntExpr ::== digit
            foundType = .int
        } else if node.key == ADDITION_NODE {                                     // Expr ::== IntExpr; IntExpr ::== digit intop Expr
            foundType = checkAddition(node: node)
        } else if node.key.first == QUOTE_NODE {                                  // Expr ::== StringExpr
            foundType = .string
        } else if node.key == EQUALITY_NODE || node.key == INEQUALITY_NODE {      // Expr ::== ( Expr boolop Expr )
            foundType = checkBooleanExpr(node: node)
        } else if node.key == TRUE_NODE || node.key == FALSE_NODE {               // Expr ::== boolval
            foundType = .boolean
        } else {                                                                  // Expr ::== Id
            foundType = checkId(node: node, checkType: .use)
        }
        guard expectedType == nil || expectedType == foundType else {
            message(type: .error, data: (expecting: expectedType!.rawValue, found: node.key, lineNumber: node.data.lineNumber))
            return nil
        }
        message(type: .success, data: (expecting: expectedType?.rawValue ?? "Any", found: node.key, lineNumber: node.data.lineNumber))
        return foundType
    }
    
    private static func checkVarDecl(node: TreeNode<ASTNode>) -> Bool {
        let type = VarType(rawValue: node.leftChild.key)!
        let value: ScopeType = (type: type, lineNumber: node.leftChild.data.lineNumber, isInitialized: false, isUsed: false)
        guard symbolTable.addCurrent(key: node.rightChild.key, value: value) else { // Assert variable not already declared
            message(type: .error, overrideMessage: "Variable [ \(node.rightChild.key) ] redeclared on line \(node.rightChild.data.lineNumber)")
            return false
        }
        message(type: .success, overrideMessage: "Variable [ \(node.rightChild.key) ] of type [ \(type.rawValue) ] declared on line \(node.rightChild.data.lineNumber)")
        return true
    }
    
    private static func checkAssignment(node: TreeNode<ASTNode>) -> Bool {
        guard let expectedType = checkId(node: node.leftChild, checkType: .initialize), // Assert variable was declared
            checkExpr(node: node.rightChild, expectedType: expectedType) != nil else { // Assert assignment is of correct type
                return false
        }
        return true
    }
    
    private static func checkId(node: TreeNode<ASTNode>, checkType: CheckType) -> VarType? {
        guard let expectedType = symbolTable.checkCurrent(key: node.key, checkType: checkType) else { // Lookup variable and get type
            message(type: .error, overrideMessage: "Variable [ \(node.key) ] on line \(node.data.lineNumber) assigned before it is declared")
            return nil
        }
        return expectedType
    }
    
    private static func checkAddition(node: TreeNode<ASTNode>) -> VarType? {
        guard Int(node.leftChild.key) != nil else { // Assert left child is an integer
            message(type: .error, data: (expecting: "int", found: node.leftChild.key, lineNumber: node.leftChild.data.lineNumber))
            return nil
        }
        message(type: .success, data: (expecting: "int", found: node.leftChild.key, lineNumber: node.leftChild.data.lineNumber))
        guard checkExpr(node: node.rightChild, expectedType: .int) != nil else { // Assert right child evaluates to int
            message(type: .error, data: (expecting: "int", found: node.rightChild.key, lineNumber: node.rightChild.data.lineNumber))
            return nil
        }
        message(type: .success, data: (expecting: "int", found: node.rightChild.key, lineNumber: node.rightChild.data.lineNumber))
        return .int
    }
    
    private static func checkBooleanExpr(node: TreeNode<ASTNode>) -> VarType? {
        guard let foundType = checkExpr(node: node.leftChild, expectedType: nil) else { // Boolops must compare same types; get type of left child
            message(type: .error, data: (expecting: "Any", found: node.leftChild.key, lineNumber: node.leftChild.data.lineNumber))
            return nil
        }
        guard checkExpr(node: node.rightChild, expectedType: foundType) != nil else { // Assert right child has same type
            message(type: .error, data: (expecting: foundType.rawValue, found: node.rightChild.key, lineNumber: node.rightChild.data.lineNumber))
            return nil
        }
        return .boolean
    }
    
    private static func checkWhileAndIf(node: TreeNode<ASTNode>) -> Bool {
        var foundType: VarType? = nil
        if node.leftChild.key == EQUALITY_NODE || node.leftChild.key == INEQUALITY_NODE { // While | If ::== ( Expr boolop Expr ) Block
            foundType = checkBooleanExpr(node: node.leftChild)
        } else if node.leftChild.key == TRUE_NODE || node.leftChild.key == FALSE_NODE {   // While | If ::== boolval Block
            foundType = .boolean
        }
        guard foundType == .boolean else { // Assert left child is boolean
            message(type: .error, data: (expecting: "boolean", found: node.leftChild.key, lineNumber: node.leftChild.data.lineNumber))
            return false
        }
        guard checkBlock(node: node.rightChild) else { // Recursively check block
            return false
        }
        message(type: .success, data: (expecting: "boolean", found: node.leftChild.key, lineNumber: node.leftChild.data.lineNumber))
        return true
    }
    
}
