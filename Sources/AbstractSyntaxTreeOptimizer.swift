//
//  AbstractSyntaxTreeOptimizer.swift
//  EXZLER
//
//  Created by EXZACKLY on 5/8/18.
//

import Foundation

class AbstractSyntaxTreeOptimizer {
    
    private static let optimizeNodeMap = [
        BOOLOP_NODE : liftBoolops,
        ADDITION_NODE : constantFold,
        EQUALITY_NODE : booleanFold,
        INEQUALITY_NODE : booleanFold
    ]
    
    static func optimize(AST: Tree<ASTNode>) -> Tree<ASTNode> {
        var hasMadeChange = false
        var queue = [AST.root] // Loop over AST
        while !queue.isEmpty {
            let currentNode = queue[0]
            queue += currentNode.children
            let action = optimizeNodeMap[currentNode.key] // Determine type of node
            hasMadeChange = action?(currentNode) ?? hasMadeChange
            queue.remove(at: 0)
        }
        return hasMadeChange ? optimize(AST: AST) : AST // Recursively loop until no changes have been made
    }
    
    private static func liftBoolops(node: TreeNode<ASTNode>) -> Bool {
        node.data.name = node.children[1].key == "==" ? "<Equality>" : "<Inequality>" // Lift boolop
        node.children = [node.children[0], node.children[2]] // Fold children
        return true
    }
    
    private static func constantFold(node: TreeNode<ASTNode>) -> Bool {
        let conditions = [{ return Int(node.leftChild.key) != nil }, { return Int(node.rightChild.key) != nil }] // Ensure left and right children are ints
        let action: (TreeNode<ASTNode>) -> String = { "\(Int($0.leftChild.key)! + Int($0.rightChild.key)!)" } // Return string of sum
        return guardThenFold(node: node, conditions: conditions, action: action)
    }
    
    private static func booleanFold(node: TreeNode<ASTNode>) -> Bool {
        if node.leftChild.key == TRUE_NODE || node.leftChild.key == FALSE_NODE {
            let conditions = [{ return node.rightChild.key == TRUE_NODE || node.rightChild.key == FALSE_NODE }] // Left node checked above; ensure right child is boolean literal
            let action: (TreeNode<ASTNode>) -> String = { ($0.key == EQUALITY_NODE) == ($0.leftChild.key == $0.rightChild.key) ? TRUE_NODE : FALSE_NODE } // Return string of result
            return guardThenFold(node: node, conditions: conditions, action: action)
        } else if Int(node.leftChild.key) != nil {
            let conditions = [{ return Int(node.leftChild.key) != nil }, { return Int(node.rightChild.key) != nil }] // Ensure left and right children are ints
            let action: (TreeNode<ASTNode>) -> String = { ($0.key == EQUALITY_NODE) == (Int($0.leftChild.key)! == Int($0.rightChild.key)) ? TRUE_NODE : FALSE_NODE }
            return guardThenFold(node: node, conditions: conditions, action: action)
        } else {
            return false
        }
    }
    
    private static func guardThenFold(node: TreeNode<ASTNode>, conditions: [() -> Bool], action: (TreeNode<ASTNode>) -> String) -> Bool {
        for condition in conditions { // Check all conditions first
            guard condition() else {
                return false // Condition not met; return false
            }
        }
        node.data.name = "[ \(action(node)) ]" // Set value of folded node
        node.children = []
        return true
    }
    
}
