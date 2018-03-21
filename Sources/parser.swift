//
//  parser.swift
//  EXZLER
//
//  Created by EXZACKLY on 2/27/18.
//

import Foundation

var tokens: [Token]!
var concreteSyntaxTree: Tree<String>!
var abstractSyntaxTree: Tree<String>!
var verbose: Bool!

func parse(tokens passedTokens: [Token], verbose isVerbose: Bool = false) -> Tree<String>? {
    tokens = passedTokens
    concreteSyntaxTree = Tree(data: "<CST>")
    abstractSyntaxTree = Tree(data: "<AST>")
    verbose = isVerbose
    
    while !tokens.isEmpty {
        guard parseProgram() else {
            print("Parsing completed with 0 warning(s) and 1 error(s)\n\nCST skipped due to parse errors\n")
            return nil
        }
        print()
    }
    
    // Print result regardless of verbose
    print("Parsing completed with 0 warning(s) and 0 error(s)\n")
    
    if verbose {
        print("\(concreteSyntaxTree!)\n")
        print("\(abstractSyntaxTree!)\n")
    }
    
    return abstractSyntaxTree
}

typealias RoutesType = [TokenType : [() -> Bool]]
func parse(routes: RoutesType) -> Bool {
    guard let route = routes[tokens[0].type] else { // Look ahead 1 token to determine route
        let foundToken = tokens[0] // Valid route not found. Instead found...
        let expected = routes.reduce(""){ $0 == "" ? $1.key.rawValue: $0 + " | " + $1.key.rawValue } // Compile valid routes
        print("ERROR: Expecting [ \(expected) ] found [ \(foundToken.data) ] on line \(foundToken.lineNumber)")
        return false
    }
    for step in route { // Follow route
        guard step() else {
            return false
        }
    }
    return true
}

func consume(tokenType: TokenType) -> () -> Bool {
    return { // Return () -> Bool closure that consumes that specified tokenType
        guard tokens[0].type == tokenType else { // Validate expected token
            let foundToken = tokens[0] // Invalid token found. Instead found...
            print("ERROR: Expecting [ \(tokenType.rawValue) ] found [ \(foundToken.data) ] on line \(foundToken.lineNumber)")
            return false
        }
        let token = tokens.removeFirst() // Consume token
        concreteSyntaxTree.addChild(data: "[ \(token.data) ]") // Add token to CST
        concreteSyntaxTree.endChild()
        
        if [.equality, .inequality, .type, .boolean, .digit, .string, .id].contains(tokenType) { // Only add important tokens to AST
            abstractSyntaxTree.addChild(data: "[ \(token.data) ]") // Add token to AST
            abstractSyntaxTree.endChild()
        }

        if verbose {
            print("PARSER -> Expecting [ \(tokenType.rawValue) ] found [ \(token.data) ] on line \(token.lineNumber)")
        }
        return true
    }
}

func add(child: String, isConcrete: Bool = true, isAbstract: Bool = false) -> () -> Bool {
    return { // Return () -> Bool closure that adds specified child to concreteSyntaxTree
        if isConcrete {
           concreteSyntaxTree.addChild(data: "<\(child)>")
        }
        if isAbstract {
            abstractSyntaxTree.addChild(data: "<\(child)>")
        }
        return true
    }
}

func endChild(isConcrete: Bool = true, isAbstract: Bool = false) -> () -> Bool {
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

let parseProgram = { return parse(routes: programRoutes) }
let programRoutes: RoutesType = [
    .leftCurlyBrace : [add(child: "Program", isAbstract: true), parseBlock, consume(tokenType: .EOP), endChild(isAbstract: true)] // Program ::== Block $
]

let parseBlock = { return parse(routes: blockRoutes) }
let blockRoutes: RoutesType = [
    .leftCurlyBrace : [add(child: "Block", isAbstract: true), consume(tokenType: .leftCurlyBrace),
                       parseStatementList, consume(tokenType: .rightCurlyBrace), endChild(isAbstract: true)] // Block ::== { StatementList }
]

let parseStatementList = { return parse(routes: statementListRoutes) }
let statementListRoute = [add(child: "StatementList"), parseStatement, parseStatementList, endChild()]
let statementListRoutes: RoutesType = [
    .print : statementListRoute,                                                              // Statement ::== PrintStatement
    .id : statementListRoute,                                                                 // Statement ::== AssignmentStatement
    .type : statementListRoute,                                                               // Statement ::== VarDecl
    .while : statementListRoute,                                                              // Statement ::== WhileStatement
    .if : statementListRoute,                                                                 // Statement ::== IfStatement
    .leftCurlyBrace : statementListRoute,                                                     // Statement ::== Block
    .rightCurlyBrace : [add(child: "StatementList"), add(child: "ε"), endChild(), endChild()] // Epsilon production
]

let parseStatement = { return parse(routes: statementRoutes) }
let statementRoutes: RoutesType = [
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

let parseExpr = { return parse(routes: exprRoutes) }
let exprRoutes: RoutesType = [
    .digit : [add(child: "Expr"), add(child: "IntExpr"), parseIntExpr, endChild(), endChild()],                    // Expr ::== IntExpr
    .string : [add(child: "Expr"), add(child: "StringExpr"), consume(tokenType: .string), endChild(), endChild()], // Expr ::== StringExpr
    .leftParenthesis : [add(child: "Expr"), parseBooleanExpr, endChild()],                                         // Expr ::== ( Expr boolop Expr )
    .boolean : [add(child: "Expr"), parseBooleanExpr, endChild()],                                                 // Expr ::== boolval
    .id : [add(child: "Expr"), add(child: "Id"), consume(tokenType: .id), endChild(), endChild()]                  // Expr ::== Id
]

let parseIntExpr = { return tokens.count > 1 && tokens[1].type == .addition ? parse(routes: intExprRoutes) : consume(tokenType: .digit)() }
let intExprRoutes: RoutesType = [
    .digit : [add(child: "Addition", isConcrete: false, isAbstract: true), consume(tokenType: .digit),
              consume(tokenType: .addition), parseExpr, endChild(isConcrete: false, isAbstract: true)] // IntExpr ::== digit intop Expr
]

let parseBooleanExpr = { return parse(routes: booleanExprRoutes) }
let booleanExprRoutes: RoutesType = [
    .leftParenthesis : [add(child: "BooleanExpr"), consume(tokenType: .leftParenthesis), parseExpr,
                        parseBoolop, parseExpr, consume(tokenType: .rightParenthesis), endChild()], // BooleanExpr ::== ( Expr boolop Expr )
    .boolean : [add(child: "BooleanExpr"), consume(tokenType: .boolean), endChild()]                // BooleanExpr ::== boolval
]

let parseBoolop = { return parse(routes: boolopRoutes) }
let boolopRoutes: RoutesType = [
    .equality : [add(child: "Boolop"), consume(tokenType: .equality), endChild()],    // boolop ::== ==
    .inequality : [add(child: "Boolop"), consume(tokenType: .inequality), endChild()] // boolop ::== !=
]
