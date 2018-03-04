//
//  parser.swift
//  EXZLER
//
//  Created by EXZACKLY on 2/27/18.
//

import Foundation

var tokens: [Token]!
var concreteSyntaxTree: Tree<String>!
var verbose: Bool!

func parse(tokens passedTokens: [Token], verbose isVerbose: Bool = false) -> Tree<String>? {
    tokens = passedTokens
    concreteSyntaxTree = Tree(data: "<Root>")
    verbose = isVerbose
    
    while !tokens.isEmpty {
        guard parseProgram() else {
            print("Parsing completed with 0 warning(s) and 1 error(s)\nCST skipped due to parse errors\n")
            return nil
        }
    }
    
    // Print result regardless of verbose
    print("Parsing completed with 0 warning(s) and 0 error(s)\n")
    
    if verbose {
        print(concreteSyntaxTree)
    }
    
    return concreteSyntaxTree
}

func parse(routes: [TokenType : [() -> Bool]]) -> Bool {
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
        if verbose {
            print("PARSER -> Expecting [ \(tokenType.rawValue) ] found [ \(token.data) ] on line \(token.lineNumber)")
        }
        return true
    }
}

func add(child: String) -> () -> Bool {
    return { // Return () -> Bool closure that adds specified child to concreteSyntaxTree
        concreteSyntaxTree.addChild(data: "<\(child)>")
        return true
    }
}

func endChild() -> () -> Bool {
    return { // Return () -> Bool closure that ends child to concreteSyntaxTree
        concreteSyntaxTree.endChild()
        return true
    }
}

let parseProgram = { return parse(routes: programRoutes) }
let programRoutes: [TokenType : [() -> Bool]] = [
    .leftCurlyBrace : [add(child: "Program"), parseBlock, consume(tokenType: .EOP), endChild()] // Program ::== Block $
]

let parseBlock = { return parse(routes: blockRoutes) }
let blockRoutes: [TokenType : [() -> Bool]] = [
    .leftCurlyBrace : [add(child: "Block"), consume(tokenType: .leftCurlyBrace), parseStatementList, consume(tokenType: .rightCurlyBrace), endChild()] // Block ::== { StatementList }
]

let parseStatementList = { return parse(routes: statementListRoutes) }
let statementListRoute = [add(child: "StatementList"), parseStatement, parseStatementList, endChild()]
let statementListRoutes: [TokenType : [() -> Bool]] = [
    .print : statementListRoute,                                                              // Statement ::== PrintStatement
    .id : statementListRoute,                                                                 // Statement ::== AssignmentStatement
    .type : statementListRoute,                                                               // Statement ::== VarDecl
    .while : statementListRoute,                                                              // Statement ::== WhileStatement
    .if : statementListRoute,                                                                 // Statement ::== IfStatement
    .leftCurlyBrace : statementListRoute,                                                     // Statement ::== Block
    .rightCurlyBrace : [add(child: "StatementList"), add(child: "ε"), endChild(), endChild()] // Epsilon production
]

let parseStatement = { return parse(routes: statementRoutes) }
let statementRoutes: [TokenType : [() -> Bool]] = [
    .print : [add(child: "Statement"), add(child: "PrintStatement"), consume(tokenType: .print),
              consume(tokenType: .leftParenthesis), parseExpr, consume(tokenType: .rightParenthesis), endChild(), endChild()],                 // Statement ::== PrintStatement
    .id : [add(child: "Statement"), add(child: "AssignmentStatement"), add(child: "Id"), consume(tokenType: .id), endChild(),
           consume(tokenType: .assignment), parseExpr, endChild(), endChild()],                                                                // Statement ::== AssignmentStatement
    .type : [add(child: "Statement"), add(child: "VarDecl"), add(child: "Type"), consume(tokenType: .type), endChild(),
             add(child: "Id"), consume(tokenType: .id), endChild(), endChild(), endChild()],                                                   // Statement ::== VarDecl
    .while : [add(child: "Statement"), add(child: "WhileStatement"), consume(tokenType: .while), parseBooleanExpr, parseBlock,
              endChild(), endChild()],                                                                                                         // Statement ::== WhileStatement
    .if : [add(child: "Statement"), add(child: "IfStatement"), consume(tokenType: .if), parseBooleanExpr, parseBlock, endChild(), endChild()], // Statement ::== IfStatement
    .leftCurlyBrace : [add(child: "Statement"), parseBlock, endChild()]                                                                        // Statement ::== Block
]

let parseExpr = { return parse(routes: exprRoutes) }
let exprRoutes: [TokenType : [() -> Bool]] = [
    .digit : [add(child: "Expr"), add(child: "IntExpr"), consume(tokenType: .digit), parseIntExpr, endChild(), endChild()], // Expr ::== IntExpr
    .string : [add(child: "Expr"), add(child: "StringExpr"), consume(tokenType: .string), endChild(), endChild()],          // Expr ::== StringExpr
    .leftParenthesis : [add(child: "Expr"), parseBooleanExpr, endChild()],                                                  // Expr ::== ( Expr boolop Expr )
    .boolean : [add(child: "Expr"), parseBooleanExpr, endChild()],                                                          // Expr ::== boolval
    .id : [add(child: "Expr"), add(child: "Id"), consume(tokenType: .id), endChild(), endChild()]                           // Expr ::== Id
]

let parseIntExpr = { return tokens[0].type == .addition ? parse(routes: intExprRoutes) : true }
let intExprRoutes: [TokenType : [() -> Bool]] = [
    .addition : [consume(tokenType: .addition), parseExpr] // IntExpr ::== digit intop Expr
]

let parseBooleanExpr = { return parse(routes: booleanExprRoutes) }
let booleanExprRoutes: [TokenType : [() -> Bool]] = [
    .leftParenthesis : [add(child: "BooleanExpr"), consume(tokenType: .leftParenthesis), parseExpr,
                        parseBoolop, parseExpr, consume(tokenType: .rightParenthesis), endChild()], // BooleanExpr ::== ( Expr boolop Expr )
    .boolean : [add(child: "BooleanExpr"), consume(tokenType: .boolean), endChild()]                // BooleanExpr ::== boolval
]

let parseBoolop = { return parse(routes: boolopRoutes) }
let boolopRoutes: [TokenType : [() -> Bool]] = [
    .equality : [add(child: "Boolop"), consume(tokenType: .equality), endChild()],    // boolop ::== ==
    .inequality : [add(child: "Boolop"), consume(tokenType: .inequality), endChild()] // boolop ::== !=
]
