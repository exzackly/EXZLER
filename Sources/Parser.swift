//
//  Parser.swift
//  EXZLER
//
//  Created by EXZACKLY on 2/27/18.
//

import Foundation

typealias ASTNode = (name: String, lineNumber: Int)

class Parser {
    
    private static var tokens: [Token]!
    private static var concreteSyntaxTree = Tree(data: "<CST>")
    private static var abstractSyntaxTree = Tree(data: (name: "<AST>", lineNumber: 0))
    private static let messenger = Messenger(prefix: "PARSER -> ")
    
    static func parse(tokens passedTokens: [Token], verbose isVerbose: Bool = false) -> Tree<ASTNode>? {
        tokens = passedTokens
        concreteSyntaxTree = Tree(data: "<CST>")
        abstractSyntaxTree = Tree(data: (name: "<AST>", lineNumber: 0))
        abstractSyntaxTree.printMethod = { node in return "\(node.data.name)\n" }
        messenger.verbose = isVerbose
        
        guard parseProgram() else {
            messenger.message(type: .system, message: "Parsing completed with 0 warning(s) and 1 error(s)\n\nCST skipped due to parse errors\n", override: true)
            return nil
        }
        
        // Print result regardless of verbose
        messenger.message(type: .system, message: "Parsing completed with 0 warning(s) and 0 error(s)\n", override: true)
        
        abstractSyntaxTree = liftBoolops(AST: abstractSyntaxTree) // Lift boolops
        
        messenger.message(type: .system, message: "\(concreteSyntaxTree)")
        messenger.message(type: .system, message: "\(abstractSyntaxTree)")
        
        return abstractSyntaxTree
    }
    
    private typealias RoutesType = [TokenType : [() -> Bool]]
    private static func parse(routes: RoutesType) -> Bool {
        guard let route = routes[tokens[0].type] else { // Look ahead 1 token to determine route
            let foundToken = tokens[0] // Valid route not found. Instead found...
            let expected = routes.reduce(""){ $0 == "" ? $1.key.rawValue: $0 + " | " + $1.key.rawValue } // Compile valid routes
            messenger.message(type: .error, message: "Expecting [ \(expected) ] found [ \(foundToken.data) ] on line \(foundToken.lineNumber)")
            return false
        }
        for step in route { // Follow route
            guard step() else {
                return false
            }
        }
        return true
    }
    
    private static func consume(tokenType: TokenType) -> () -> Bool {
        return { // Return () -> Bool closure that consumes that specified tokenType
            guard tokens[0].type == tokenType else { // Validate expected token
                let foundToken = tokens[0] // Invalid token found. Instead found...
                messenger.message(type: .error, message: "Expecting [ \(tokenType.rawValue) ] found [ \(foundToken.data) ] on line \(foundToken.lineNumber)")
                return false
            }
            let token = tokens.removeFirst() // Consume token
            concreteSyntaxTree.addChild(data: "[ \(token.data) ]") // Add token to CST
            concreteSyntaxTree.endChild()
            
            if [.equality, .inequality, .type, .boolean, .digit, .string, .id].contains(tokenType) { // Only add important tokens to AST
                let ASTNode = (name: "[ \(token.data) ]", lineNumber: token.lineNumber)
                abstractSyntaxTree.addChild(data: ASTNode) // Add token to AST
                abstractSyntaxTree.endChild()
            }
            
            messenger.message(type: .success, message: "PARSER -> Expecting [ \(tokenType.rawValue) ] found [ \(token.data) ] on line \(token.lineNumber)")
            return true
        }
    }
    
    private static func add(child: String, isConcrete: Bool = true, isAbstract: Bool = false) -> () -> Bool {
        return { // Return () -> Bool closure that adds specified child to concreteSyntaxTree
            if isConcrete {
                concreteSyntaxTree.addChild(data: "<\(child)>")
            }
            if isAbstract {
                let ASTNode = (name: "<\(child)>", lineNumber: tokens[0].lineNumber)
                abstractSyntaxTree.addChild(data: ASTNode)
            }
            return true
        }
    }
    
    private static func endChild(isConcrete: Bool = true, isAbstract: Bool = false) -> () -> Bool {
        return { // Return () -> Bool closure that ends child to concreteSyntaxTree
            if isConcrete {
                concreteSyntaxTree.endChild()
            }
            if isAbstract {
                abstractSyntaxTree.endChild()
            }
            return true
        }
    }
    
    private static let parseProgram = { return parse(routes: programRoutes) }
    private static let programRoutes: RoutesType = [
        .leftCurlyBrace : [add(child: "Program", isAbstract: true), parseBlock, consume(tokenType: .EOP), endChild(isAbstract: true)] // Program ::== Block $
    ]
    
    private static let parseBlock = { return parse(routes: blockRoutes) }
    private static let blockRoutes: RoutesType = [
        .leftCurlyBrace : [add(child: "Block", isAbstract: true), consume(tokenType: .leftCurlyBrace),
                           parseStatementList, consume(tokenType: .rightCurlyBrace), endChild(isAbstract: true)] // Block ::== { StatementList }
    ]
    
    private static let parseStatementList = { return parse(routes: statementListRoutes) }
    private static let statementListRoute = [add(child: "StatementList"), parseStatement, parseStatementList, endChild()]
    private static let statementListRoutes: RoutesType = [
        .print : statementListRoute,                                                              // Statement ::== PrintStatement
        .id : statementListRoute,                                                                 // Statement ::== AssignmentStatement
        .type : statementListRoute,                                                               // Statement ::== VarDecl
        .while : statementListRoute,                                                              // Statement ::== WhileStatement
        .if : statementListRoute,                                                                 // Statement ::== IfStatement
        .leftCurlyBrace : statementListRoute,                                                     // Statement ::== Block
        .rightCurlyBrace : [add(child: "StatementList"), add(child: "ε"), endChild(), endChild()] // Epsilon production
    ]
    
    private static let parseStatement = { return parse(routes: statementRoutes) }
    private static let statementRoutes: RoutesType = [
        .print : [add(child: "Statement"), add(child: "PrintStatement", isAbstract: true), consume(tokenType: .print),
                  consume(tokenType: .leftParenthesis), parseExpr, consume(tokenType: .rightParenthesis), endChild(isAbstract: true), endChild()],   // Statement ::== PrintStatement
        .id : [add(child: "Statement"), add(child: "AssignmentStatement", isAbstract: true), add(child: "Id"), consume(tokenType: .id), endChild(),
               consume(tokenType: .assignment), parseExpr, endChild(isAbstract: true), endChild()],                                                  // Statement ::== AssignmentStatement
        .type : [add(child: "Statement"), add(child: "VarDecl", isAbstract: true), add(child: "Type"), consume(tokenType: .type), endChild(),
                 add(child: "Id"), consume(tokenType: .id), endChild(), endChild(isAbstract: true), endChild()],                                     // Statement ::== VarDecl
        .while : [add(child: "Statement"), add(child: "WhileStatement", isAbstract: true), consume(tokenType: .while), parseBooleanExpr, parseBlock,
                  endChild(isAbstract: true), endChild()],                                                                                           // Statement ::== WhileStatement
        .if : [add(child: "Statement"), add(child: "IfStatement", isAbstract: true), consume(tokenType: .if), parseBooleanExpr, parseBlock,
               endChild(isAbstract: true), endChild()],                                                                                              // Statement ::== IfStatement
        .leftCurlyBrace : [add(child: "Statement"), parseBlock, endChild()]                                                                          // Statement ::== Block
    ]
    
    private static let parseExpr = { return parse(routes: exprRoutes) }
    private static let exprRoutes: RoutesType = [
        .digit : [add(child: "Expr"), add(child: "IntExpr"), parseIntExpr, endChild(), endChild()],                    // Expr ::== IntExpr
        .string : [add(child: "Expr"), add(child: "StringExpr"), consume(tokenType: .string), endChild(), endChild()], // Expr ::== StringExpr
        .leftParenthesis : [add(child: "Expr"), parseBooleanExpr, endChild()],                                         // Expr ::== ( Expr boolop Expr )
        .boolean : [add(child: "Expr"), parseBooleanExpr, endChild()],                                                 // Expr ::== boolval
        .id : [add(child: "Expr"), add(child: "Id"), consume(tokenType: .id), endChild(), endChild()]                  // Expr ::== Id
    ]
    
    private static let parseIntExpr = { return tokens.count > 1 && tokens[1].type == .addition ? parse(routes: intExprRoutes) : consume(tokenType: .digit)() }
    private static let intExprRoutes: RoutesType = [
        .digit : [add(child: "Addition", isConcrete: false, isAbstract: true), consume(tokenType: .digit),
                  consume(tokenType: .addition), parseExpr, endChild(isConcrete: false, isAbstract: true)] // IntExpr ::== digit intop Expr
    ]
    
    private static let parseBooleanExpr = { return parse(routes: booleanExprRoutes) }
    private static let booleanExprRoutes: RoutesType = [
        .leftParenthesis : [add(child: "BooleanExpr"), add(child: "Boolop", isConcrete: false, isAbstract: true),
                            consume(tokenType: .leftParenthesis), parseExpr, parseBoolop, parseExpr,
                            consume(tokenType: .rightParenthesis), endChild(isConcrete: false, isAbstract: true), endChild()], // BooleanExpr ::== ( Expr boolop Expr )
        .boolean : [add(child: "BooleanExpr"), consume(tokenType: .boolean), endChild()]                                       // BooleanExpr ::== boolval
    ]
    
    private static let parseBoolop = { return parse(routes: boolopRoutes) }
    private static let boolopRoutes: RoutesType = [
        .equality : [add(child: "Boolop"), consume(tokenType: .equality), endChild()],    // boolop ::== ==
        .inequality : [add(child: "Boolop"), consume(tokenType: .inequality), endChild()] // boolop ::== !=
    ]
    
    private static func liftBoolops(AST: Tree<ASTNode>) -> Tree<ASTNode> {
        var queue = [AST.root] // Loop over AST
        while !queue.isEmpty {
            let currentNode = queue[0]
            queue += currentNode.children
            if currentNode.key == "Boolop" { // Locate Boolop subtrees
                let liftedName = currentNode.children[1].key == "==" ? "<Equality>" : "<Inequality>"
                currentNode.data.name = liftedName // Lift boolop
                currentNode.children = [currentNode.children[0], currentNode.children[2]] // Fold children
            }
            queue.remove(at: 0)
        }
        return AST
    }
    
}
