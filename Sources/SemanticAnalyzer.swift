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
    
    private static var symbolTable = SymbolTable(data: [:])
    private static var idIndex = 0
    private static let messenger = Messenger(prefix: "SEMANTIC ANALYZER -> ")
    
    static func analyze(AST: Tree<ASTNode>, verbose isVerbose: Bool = false) -> SymbolTable? {
        symbolTable = SymbolTable(data: [:])
        messenger.verbose = isVerbose
        
        guard checkBlock(node: AST.root.child.child) else { // Isolate main program block
            return nil
        }
        
        let (warningCount, warningMessages) = symbolTable.check()
        
        for message in warningMessages {
            messenger.message(type: .warning, message: message)
        }
        
        // Print result regardless of verbose
        messenger.message(type: .system, message: "Semantic analyzing completed with \(warningCount) warning(s) and 0 error(s)\n", override: true)

        messenger.message(type: .system, message: symbolTable.description)
        
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
    
    private static let messageTemplate: (String, String, Int) -> String = { (expecting, found, lineNumber) in "Expecting [ \(expecting) ] found [ \(found) ] on line \(lineNumber)" }
    private static let errorTemplate = { "\nSemantic analyzing completed with 0 warning(s) and 1 error(s)\n\nSymbol Table skipped due to semantic analysis errors\n" }
    
    private static func checkExpr(node: TreeNode<ASTNode>, expectedType: VarType?) -> VarType? {
        var foundType: VarType? = nil
        if Int(node.key) != nil {                                            // Expr ::== IntExpr; IntExpr ::== digit
            foundType = .int
        } else if node.key == ADDITION_NODE {                                // Expr ::== IntExpr; IntExpr ::== digit intop Expr
            foundType = checkAddition(node: node)
        } else if node.key.first == QUOTE_NODE {                             // Expr ::== StringExpr
            foundType = .string
        } else if node.key == EQUALITY_NODE || node.key == INEQUALITY_NODE { // Expr ::== ( Expr boolop Expr )
            foundType = checkBooleanExpr(node: node)
        } else if node.key == TRUE_NODE || node.key == FALSE_NODE {          // Expr ::== boolval
            foundType = .boolean
        } else {                                                             // Expr ::== Id
            foundType = checkId(node: node, checkType: .use)
        }
        guard foundType != nil && (expectedType == nil || expectedType == foundType) else {
            messenger.message(type: .error, message: messageTemplate(expectedType?.rawValue ?? "Any", node.key, node.data.lineNumber) + errorTemplate())
            return nil
        }
        messenger.message(type: .success, message: messageTemplate(expectedType?.rawValue ?? "Any", node.key, node.data.lineNumber))
        return foundType
    }
    
    private static func checkVarDecl(node: TreeNode<ASTNode>) -> Bool {
        let type = VarType(rawValue: node.leftChild.key)!
        let value: ScopeType = (type: type, lineNumber: node.leftChild.data.lineNumber, isInitialized: false, isUsed: false, idIndex: idIndex)
        guard symbolTable.addCurrent(key: node.rightChild.key, value: value) else { // Assert variable not already declared
            messenger.message(type: .error, message: "Variable [ \(node.rightChild.key) ] redeclared on line \(node.rightChild.data.lineNumber)" + errorTemplate())
            return false
        }
        node.rightChild.data.type = type
        node.rightChild.data.idIndex = idIndex
        idIndex += 1
        messenger.message(type: .success, message: "Variable [ \(node.rightChild.key) ] of type [ \(type.rawValue) ] declared on line \(node.rightChild.data.lineNumber)")
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
        guard let (expectedType, idIndex) = symbolTable.checkCurrent(key: node.key, checkType: checkType) else { // Lookup variable and get type
            messenger.message(type: .error, message: "Variable [ \(node.key) ] on line \(node.data.lineNumber) used before it is declared" + errorTemplate())
            return nil
        }
        node.data.type = expectedType
        node.data.idIndex = idIndex
        return expectedType
    }
    
    private static func checkAddition(node: TreeNode<ASTNode>) -> VarType? {
        guard Int(node.leftChild.key) != nil else { // Assert left child is an integer
            messenger.message(type: .error, message: messageTemplate("int", node.leftChild.key, node.leftChild.data.lineNumber) + errorTemplate())
            return nil
        }
        messenger.message(type: .success, message: messageTemplate("int", node.leftChild.key, node.leftChild.data.lineNumber))
        guard checkExpr(node: node.rightChild, expectedType: .int) != nil else { // Assert right child evaluates to int
            messenger.message(type: .error, message: messageTemplate("int", node.rightChild.key, node.rightChild.data.lineNumber) + errorTemplate())
            return nil
        }
        messenger.message(type: .success, message: messageTemplate("int", node.rightChild.key, node.rightChild.data.lineNumber))
        return .int
    }
    
    private static func checkBooleanExpr(node: TreeNode<ASTNode>) -> VarType? {
        guard let foundType = checkExpr(node: node.leftChild, expectedType: nil) else { // Boolops must compare same types; get type of left child
            messenger.message(type: .error, message: messageTemplate("Any", node.leftChild.key, node.leftChild.data.lineNumber) + errorTemplate())
            return nil
        }
        guard checkExpr(node: node.rightChild, expectedType: foundType) != nil else { // Assert right child has same type
            messenger.message(type: .error, message: messageTemplate(foundType.rawValue, node.rightChild.key, node.rightChild.data.lineNumber) + errorTemplate())
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
            messenger.message(type: .error, message: messageTemplate("boolean", node.leftChild.key, node.leftChild.data.lineNumber) + errorTemplate())
            return false
        }
        guard checkBlock(node: node.rightChild) else { // Recursively check block
            return false
        }
        messenger.message(type: .success, message: messageTemplate("boolean", node.leftChild.key, node.leftChild.data.lineNumber))
        return true
    }
    
}
