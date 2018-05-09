//
//  CodeGenerator.swift
//  EXZLER
//
//  Created by EXZACKLY on 4/21/18.
//

import Foundation

class CodeGenerator {
    
    private static var codeBuilder = CodeBuilder(messenger: messenger)
    private static var messenger: Messenger!
    
    private static let BRANCH_AROUND_SIZE = 254 // 256 bytes program size - 2 bytes for BNE op code and operand
    
    static func generate(AST: Tree<ASTNode>, verbose isVerbose: Bool = false, emit: @escaping (String, String, String) -> ()) -> String? {
        messenger = Messenger(prefix: "CODE GENERATOR", verbose: isVerbose, emit: emit)
        codeBuilder = CodeBuilder(messenger: messenger)
        
        generateBlock(node: AST.root.child.child) // Isolate main program block
        codeBuilder.break()
        
        guard let code = codeBuilder.exportCode() else {
            messenger.message(type: .system, message: "Code generating completed with 0 warning(s) and 1 error(s)\n", override: true)
            return nil
        }
        
        // Print result regardless of verbose
        messenger.message(type: .system, message: "Code generating completed with 0 warning(s) and 0 error(s)\n", override: true)
        return code
    }
    
    private static let generateBlockNodeMap = [
        "PrintStatement" : generatePrint,
        "AssignmentStatement" : generateAssignment,
        "VarDecl" : generateVarDecl,
        WHILE_STATEMENT_NODE : generateWhile,
        IF_STATEMENT_NODE : generateIf,
        "Block" : generateBlock
    ]
    
    private static func generateBlock(node: TreeNode<ASTNode>) {
        for child in node.children { // Iterate over all children nodes
            let action = generateBlockNodeMap[child.key]! // Determine type of node
            action(child) // Generate code for node
        }
    }
    
    private static func generatePrint(node: TreeNode<ASTNode>) {
        messenger.message(type: .success, message: "Print statement found")
        let varType = generateExpr(node: node.child) // Calculate expression, store in accumulator, and grab type of expression
        let systemCallXRegister = varType == .int ? 1 : 2 // 1 for int, 2 for boolean and strings
        codeBuilder.loadXRegister(with: systemCallXRegister)
        let location = codeBuilder.generateTemporaryLocation().location
        codeBuilder.storeAccumulator(at: location) // Store accumulator in memory so that we can load into y register
        codeBuilder.loadYRegister(from: location)
        codeBuilder.systemCall()
        codeBuilder.recycle(location: location) // Recycling is good
    }
    
    private static func generateExpr(node: TreeNode<ASTNode>) -> VarType {
        messenger.message(type: .success, message: "Expression found")
        if Int(node.key) != nil {                                            // Expr ::== IntExpr; IntExpr ::== digit
            codeBuilder.loadAccumulator(with: Int(node.key)!)
            return .int
        } else if node.key == ADDITION_NODE {                                // Expr ::== IntExpr; IntExpr ::== digit intop Expr
            generateAddition(node: node)
            return .int
        } else if node.key.first == QUOTE_NODE {                             // Expr ::== StringExpr
            let start = node.key.index(node.key.startIndex, offsetBy: 1)
            let end = node.key.index(node.key.endIndex, offsetBy: -1)
            let literal = String(node.key[start..<end])
            // Determine location of string literal
            let location = codeBuilder.stringLocation(for: literal)
            codeBuilder.loadAccumulator(with: location)
            return .string
        } else if node.key == EQUALITY_NODE || node.key == INEQUALITY_NODE { // Expr ::== ( Expr boolop Expr )
            generateBooleanExpr(node: node)
            generateBoolval(node: node)
            return .boolean
        } else if node.key == TRUE_NODE || node.key == FALSE_NODE {          // Expr ::== boolval
            // Determine location of boolean literal
            let location = codeBuilder.stringLocation(for: node.key)
            codeBuilder.loadAccumulator(with: location)
            return .boolean
        } else {                                                             // Expr ::== Id
            generateId(node: node)
            return node.data.type!
        }
    }
    
    private static func generateVarDecl(node: TreeNode<ASTNode>) {
        messenger.message(type: .success, message: "Variable declaration found")
        let temporaryLocation = codeBuilder.temporaryLocation(for: node.rightChild.data) // Creates location and stores in idMap
        if node.leftChild.key == "int" && temporaryLocation.isRecycled { // Initialize ints to 0 if temporary location is recycled
            codeBuilder.loadAccumulator(with: 0)
            codeBuilder.storeAccumulator(at: temporaryLocation.location)
        } else if node.leftChild.key == "boolean" || node.leftChild.key == "string" { // Initialize booleans and strings
            let defaultString = node.leftChild.key == "boolean" ? FALSE_NODE : "" // // Booleans = false and strings = empty string
            let stringLocation = codeBuilder.stringLocation(for: defaultString) // Determine location of false or empty string
            codeBuilder.loadAccumulator(with: stringLocation)
            codeBuilder.storeAccumulator(at: temporaryLocation.location) // Store pointer to string in memory
        }
    }
    
    private static func generateAssignment(node: TreeNode<ASTNode>) {
        messenger.message(type: .success, message: "Assignment found")
        _ = generateExpr(node: node.rightChild) // Calculate expression and store in accumulator
        let location = codeBuilder.temporaryLocation(for: node.leftChild.data).location // Get location of variable
        codeBuilder.storeAccumulator(at: location) // Update variable from accumulator
    }
    
    private static func generateId(node: TreeNode<ASTNode>) {
        messenger.message(type: .success, message: "Id found")
        let location = codeBuilder.temporaryLocation(for: node.data).location // Lookup location of id
        codeBuilder.loadAccumulator(from: location)
    }
    
    private static func generateAddition(node: TreeNode<ASTNode>) {
        messenger.message(type: .success, message: "Addition found")
        let location = codeBuilder.generateTemporaryLocation().location
        let literal = Int(node.leftChild.key)! // Calculate integer literal
        codeBuilder.loadAccumulator(with: literal) // Load integer literal in accumulator
        codeBuilder.storeAccumulator(at: location) // Store integer literal
        _ = generateExpr(node: node.rightChild) // Calculate expresesion and store in accumulator
        codeBuilder.addWithCarry(from: location)
        codeBuilder.recycle(location: location) // Recycling is good
    }
    
    private static func generateBooleanExpr(node: TreeNode<ASTNode>) {
        messenger.message(type: .success, message: "Boolean expression found")
        if node.key == TRUE_NODE {
            generateSetZFlag(to: true)
        } else if node.key == FALSE_NODE {
            generateSetZFlag(to: false)
        } else {
            _ = generateExpr(node: node.leftChild) // Calculate left child expression and store in accumulator
            let leftLocation = codeBuilder.generateTemporaryLocation().location
            codeBuilder.storeAccumulator(at: leftLocation) // Store value of left expression
            _ = generateExpr(node: node.rightChild) // Calculate right child expression and store in accumulator
            let rightLocation = codeBuilder.generateTemporaryLocation().location
            codeBuilder.storeAccumulator(at: rightLocation) // Store value of right expression
            codeBuilder.loadXRegister(from: leftLocation) // Load value of left child in x register
            codeBuilder.compareXRegister(to: rightLocation) // Compare x register to value of right expression
            if node.key == INEQUALITY_NODE { // Flip z-flag if inequality
                codeBuilder.loadAccumulator(with: 0) // We are going to compare with 0 in x register
                codeBuilder.branchIfNotEqual(bytes: 2) // If z flag was false, jump so accumulator remains 0 to set true z flag true
                codeBuilder.loadAccumulator(with: 1) // If z flag was true, set accumulator to 1 to set z flag false
                codeBuilder.loadXRegister(with: 0) // Compare above with 0
                codeBuilder.storeAccumulator(at: leftLocation)
                codeBuilder.compareXRegister(to: leftLocation)
            }
            codeBuilder.recycle(location: leftLocation) // Recycling is good
            codeBuilder.recycle(location: rightLocation) // Recycling is still good
        }
    }
    
    private static func generateWhile(node: TreeNode<ASTNode>) {
        messenger.message(type: .success, message: "While statement found")
        let startConditional = codeBuilder.codeSize() // Record start of loop to jump back to
        generateBooleanExpr(node: node.leftChild) // Set z flag
        let jumpName = codeBuilder.branchIfNotEqualTemporary() // Create placeholder jump
        let startBlock = codeBuilder.codeSize() // Record start of block to calculate jump on false
        generateBlock(node: node.rightChild) // Generate code for block
        generateSetZFlag(to: false) // Set z flag to false for unconditional jump
        let endConditional = codeBuilder.codeSize() // Record end of loop to calculate jump back distance
        codeBuilder.branchIfNotEqual(bytes: (BRANCH_AROUND_SIZE+startConditional)-endConditional) // Wrap-around jump to start of loop
        let endBlock = codeBuilder.codeSize() // Record end of block to calculate jump on false
        codeBuilder.temporaryJump(named: jumpName, length: endBlock-startBlock)
    }
    
    private static func generateIf(node: TreeNode<ASTNode>) {
        messenger.message(type: .success, message: "If statement found")
        generateBooleanExpr(node: node.leftChild) // Set z flag
        let jumpName = codeBuilder.branchIfNotEqualTemporary() // Create placeholder jump
        let start = codeBuilder.codeSize() // Record start of block to calculate jump on false
        generateBlock(node: node.rightChild) // Generate code for block
        let end = codeBuilder.codeSize() // Record end of block to calculate jump on false
        codeBuilder.temporaryJump(named: jumpName, length: end-start)
    }
    
    private static func generateSetZFlag(to zFlagValue: Bool) {
        codeBuilder.loadAccumulator(with: 0) // We are going to compare to 0
        let location = codeBuilder.generateTemporaryLocation().location
        codeBuilder.storeAccumulator(at: location)
        let compareValue = zFlagValue ? 0 : 1 // Compare to 0 to set z flag to true, or to 1 to set z flag false
        codeBuilder.loadXRegister(with: compareValue)
        codeBuilder.compareXRegister(to: location)
        codeBuilder.recycle(location: location) // Recycling is good
    }
    
    private static func generateBoolval(node: TreeNode<ASTNode>) {
        codeBuilder.branchIfNotEqual(bytes: 14) // Optionally jump to false
        // If first result (did not jump)...
        let trueLocation = codeBuilder.stringLocation(for: TRUE_NODE) // Determine location of first result
        generateSetZFlag(to: false)
        codeBuilder.loadAccumulator(with: trueLocation) // Load location of first result to accumulator
        codeBuilder.branchIfNotEqual(bytes: 2) // Unconditionally jump past setting accumulator to second result
        // If second result (jumped)
        let falseLocation = codeBuilder.stringLocation(for: FALSE_NODE) // Determine location of second result
        codeBuilder.loadAccumulator(with: falseLocation) // Load location of second result to accumulator
    }

}
