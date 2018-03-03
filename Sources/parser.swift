//
//  parser.swift
//  EXZLER
//
//  Created by EXZACKLY on 2/27/18.
//

import Foundation

var _tokens: [Token] = []

func parse(tokens: [Token], verbose: Bool = false) -> Bool? {
    _tokens = tokens
    
    guard parseBlock() && consume(tokenType: .EOP)() else {
        print("Parsing completed with 0 warning(s) and 1 error(s)\n")
        return nil
    }
    
    // Print result regardless of verbose
    print("Parsing completed with 0 warning(s) and 0 error(s)\n")
    
    //TODO: Return CST
    return true
}

func parse(routes: [TokenType : [() -> Bool]]) -> Bool {
    guard let route = routes[_tokens[0].type] else {
        let foundToken = _tokens[0]
        let expected = routes.reduce(""){ $0 == "" ? $1.key.rawValue: $0 + " | " + $1.key.rawValue }
        print("ERROR: Expecting [ \(expected) ] found [ \(foundToken.data) ] on line \(foundToken.lineNumber)")
        return false
    }
    for step in route {
        guard step() else {
            return false
        }
    }
    return true
}

func consume(tokenType: TokenType) -> () -> Bool {
    return { // Return () -> Bool closure that consumes that specified tokenType
        guard _tokens[0].type == tokenType else {
            let foundToken = _tokens[0]
            print("ERROR: Expecting [ \(tokenType.rawValue) ] found [ \(foundToken.data) ] on line \(foundToken.lineNumber)")
            return false
        }
        let token = _tokens.removeFirst()
        print("PARSER -> Expecting [ \(tokenType.rawValue) ] found [ \(token.data) ] on line \(token.lineNumber)")
        return true
    }
}

let parseBlock = { return parse(routes: blockRoutes) }
let blockRoutes: [TokenType : [() -> Bool]] = [
    .leftCurlyBrace : [consume(tokenType: .leftCurlyBrace), parseStatementList, consume(tokenType: .rightCurlyBrace)] // Block ::== { StatementList }
]

let parseStatementList = { return parse(routes: statementListRoutes) }
let statementListRoutes: [TokenType : [() -> Bool]] = [
    .print : [parseStatement, parseStatementList],          // Statement ::== PrintStatement
    .id : [parseStatement, parseStatementList],             // Statement ::== AssignmentStatement
    .type : [parseStatement, parseStatementList],           // Statement ::== VarDecl
    .while : [parseStatement, parseStatementList],          // Statement ::== WhileStatement
    .if : [parseStatement, parseStatementList],             // Statement ::== IfStatement
    .leftCurlyBrace : [parseStatement, parseStatementList], // Statement ::== Block
    .rightCurlyBrace : []                                   // Epsilon production
]

let parseStatement = { return parse(routes: statementRoutes) }
let statementRoutes: [TokenType : [() -> Bool]] = [
    .print : [consume(tokenType: .print), consume(tokenType: .leftParenthesis),
              parseExpr, consume(tokenType: .rightParenthesis)],                 // Statement ::== PrintStatement
    .id : [consume(tokenType: .id), consume(tokenType: .assignment), parseExpr], // Statement ::== AssignmentStatement
    .type : [consume(tokenType: .type), consume(tokenType: .id)],                // Statement ::== VarDecl
    .while : [consume(tokenType: .while), parseBooleanExpr, parseBlock],         // Statement ::== WhileStatement
    .if : [consume(tokenType: .if), parseBooleanExpr, parseBlock],               // Statement ::== IfStatement
    .leftCurlyBrace : [parseBlock]                                               // Statement ::== Block
]

let parseExpr = { return parse(routes: exprRoutes) }
let exprRoutes: [TokenType : [() -> Bool]] = [
    .digit : [consume(tokenType: .digit), parseIntExpr], // Expr ::== IntExpr
    .string : [consume(tokenType: .string)],             // Expr ::== StringExpr
    .leftParenthesis : [parseBooleanExpr],               // Expr ::== ( Expr boolop Expr )
    .boolean : [parseBooleanExpr],                       // Expr ::== boolval
    .id : [consume(tokenType: .id)]                      // Expr ::== Id
]

let parseIntExpr = { return _tokens[0].type == .addition ? parse(routes: intExprRoutes) : true }
let intExprRoutes: [TokenType : [() -> Bool]] = [
    .addition : [consume(tokenType: .addition), parseExpr] // IntExpr ::== digit intop Expr
]

let parseBooleanExpr = { return parse(routes: booleanExprRoutes) }
let booleanExprRoutes: [TokenType : [() -> Bool]] = [
    .leftParenthesis : [consume(tokenType: .leftParenthesis), parseExpr,
                        parseBoolop, parseExpr, consume(tokenType: .rightParenthesis)], // BooleanExpr ::== ( Expr boolop Expr )
    .boolean : [consume(tokenType: .boolean)]                                           // BooleanExpr ::== boolval
]

let parseBoolop = { return parse(routes: boolopRoutes) }
let boolopRoutes: [TokenType : [() -> Bool]] = [
    .equality : [consume(tokenType: .equality)],    // boolop ::== ==
    .inequality : [consume(tokenType: .inequality)] // boolop ::== !=
]
