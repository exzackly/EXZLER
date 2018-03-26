//
//  Tree.swift
//  EXZLER
//
//  Created by EXZACKLY on 3/3/18.
//

import Foundation
class TreeNode<T>: CustomStringConvertible {
    var data: T
    var parent: TreeNode? = nil
    var children: [TreeNode] = []
    
    var description: String {
        return "\(data)"
    }
    
    init(data: T) {
        self.data = data
    }
}

class Tree<T>: CustomStringConvertible {
    
    let root: TreeNode<T>
    var current: TreeNode<T>
    var printMethod: ((TreeNode<T>) -> String)? = nil
    
    init(data: T) {
        self.root = TreeNode(data: data)
        self.current = root
    }
    
    var description: String {
        return expand(node: self.root)
    }
    
    func addChild(data: T) {
        let newChild = TreeNode(data: data)
        newChild.parent = current
        current.children.append(newChild)
        current = newChild
    }
    
    func endChild() {
        current = current.parent ?? current
    }
    
    func expand(node: TreeNode<T>, depth: Int = 0) -> String {
        var expanded = ""
        for _ in 0..<depth {
            expanded += "-"
        }
        expanded += printMethod?(node) ?? "\(node.data)\n"
        for child in node.children {
            expanded += expand(node: child, depth: depth+1)
        }
        return expanded
    }
    
}
