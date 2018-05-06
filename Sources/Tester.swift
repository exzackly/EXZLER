//
//  Tester.swift
//  EXZLER
//
//  Created by EXZACKLY on 2/6/18.
//

import Foundation

class Tester {
    
    enum Tests {
        case lexing
        case parsing
        case semanticAnalyzing
        case codeGenerating
    }
    
    static func test(_ tests: [Tests]) {
        for test in tests {
            switch test {
            case .lexing:
                testLexing()
            case .parsing:
                testParsing()
            case .semanticAnalyzing:
                testSemanticAnalyzing()
            case .codeGenerating:
                testCodeGenerating()
            }
        }
    }
    
    private static let lexingTests = [
        /* Valid lex */
        "{}$",
        "{{{{{{}}}}}}$",
        "{{{{{{}}} /* comments are ignored */ }}}}$",
        "{print(\"int a\")}$", // int should be parsed as part of string
        "int i f = 5", // i and f should be ids
        "{}()+==!==ifwhileprinttruefalseintbooleanstring0123456789\"exzackly\"abcdefghijklmnopqrstuvwxyz$", // Test everything
        "{{{{{{}}} /* forget end of program token */ }}}", // Forget end of program token ($)
        "{{{{{{}}} /* end of token in comment $ */ }}}$", // End of token in comment
        "/* Long Test Case - Everything Except Boolean Declaration */\n{\n/* Int Declaration */\nint a\nint b\nboolean c\nboolean d\na = 0\nb = 0\nc = true\nd = false\n/* While Loop */\nwhile (a != 3) {\nprint(a)\nwhile (b != 3) {\nprint(b)\nb = 1 + b\nif (b == 2) {\n/* Print Statement */print(\"there is no spoon\"/* This will do nothing */)\n}\n}\nb = 0\na = 1 + a\n}\n}$", // Multiple lines
        "/*LongTestCase-EverythingExceptBooleanDeclaration*/{/*IntDeclaration*/intaintbbooleancbooleanda=0b=0c=trued=false/*WhileLoop*/while(a!=3){print(a)while(b!=3){print(b)b=1+bif(b==2){/*PrintStatement*/print(\"there is no spoon\"/*Thiswilldonothing*/)}}b=0a=1+a}}$", // No spaces
        
        /* Error cases */
        "{int    @}$",
        "{\nprint(\"12\")\n}$",
        "{\"two\nlines\"}$",
        "{ /* comments are still ignored */ int @}$",
        "{ print(\"invalid @\")}$", // Invalid token in string
        "{ print(\"invalid 7\")}$" // Digit invalid in string
    ]
    
    private static func testLexing() {
        for test in lexingTests {
            print(test + "\n")
            _ = Lexer.lex(program: test, verbose: true)
            print()
        }
    }
    
    private static let parsingTests = [
        /* Valid parse */
        "{}$",
        "{{{{{{}}}}}}$",
        "{if (a == 3+b) {}}$",
        "{if (z == 7+2+1) {}}$",
        "{print(\"int a\")}$", // int should be parsed as part of string
        "{{{{{{}}} /* forget end of program token */ }}}", // Forget end of program token ($)
        "{{{{{{}}} /* end of token in comment $ */ }}}$", // End of token in comment
        "/* Long Test Case - Everything Except Boolean Declaration */\n{\n/* Int Declaration */\nint a\nint b\nboolean c\nboolean d\na = 0\nb = 0\nc = true\nd = false\n/* While Loop */\nwhile (a != 3) {\nprint(a)\nwhile (b != 3) {\nprint(b)\nb = 1 + b\nif (b == 2) {\n/* Print Statement */print(\"there is no spoon\"/* This will do nothing */)\n}\n}\nb = 0\na = 1 + a\n}\n}$", // Multiple lines
        "/*LongTestCase-EverythingExceptBooleanDeclaration*/{/*IntDeclaration*/intaintbbooleancbooleanda=0b=0c=trued=false/*WhileLoop*/while(a!=3){print(a)while(b!=3){print(b)b=1+bif(b==2){/*PrintStatement*/print(\"there is no spoon\"/*Thiswilldonothing*/)}}b=0a=1+a}}$", // No spaces
        
        /* Error cases */
        "{{{{{{}}} /* comments are ignored */ }}}}$", // Unmatched braces
        "{if (a == c+7) {}}$" // id+digit is invalid
    ]
    
    private static func testParsing() {
        for test in parsingTests {
            print(test + "\n")
            let tokens = Lexer.lex(program: test, verbose: true)!
            _ = Parser.parse(tokens: tokens, verbose: true)
            print()
        }
    }
    
    private static let semanticAnalyzingTests = [
        /* valid semantic analysis */
        "{}$", // 0 warnings or errors
        "{{{{{{}}}}}}$", // 0 warnings or errors
        "{boolean a a = true boolean b b = true if (a == b) {}}$", // 0 warnings or errors
        "{ int a { stringa a=\"exzackly\" print(a) } a=7 print(a) }$", // 0 warnings or errors
        "{int z if (z == 7+2+1) {}}$", // 1 warning; z not initialized
        "{inta{intb}{{{intc}}}{intd}intee=1+a}$", // 5 warnings; a-d not initialized; e not used
        "/*LongTestCase-EverythingExceptBooleanDeclaration*/{/*IntDeclaration*/intaintbbooleancbooleanda=0b=0c=trued=false/*WhileLoop*/while(a!=3){print(a)while(b!=3){print(b)b=1+bif(b==2){/*PrintStatement*/print(\"there is no spoon\"/*Thiswilldonothing*/)}}b=0a=1+a}}$", // No spaces; 2 warnings; c-d not used
        "{intaa=0booleanbb=falsebooleancc=truewhile(((a!=9)==(\"test\"!=\"alan\"))==((5==5)!=(b==c))){print(\"a\")stringdd=\"yes\"print(d){intaa=5}}}$", // Nested boolean expressions; 1 warning 0 errors
        "{intii=0stringss=\"hello\"booleanbb=(true==(1!=2))if(b==true){while(true!=(b!=(false==(2!=3)))){i=1+iprint(s)}}print(\"uglycode\")}$", // Nested boolean expressions; 0 warnings and 0 errors
        
        /* Error cases */
        "{boolean a a = true int b b = 7 if (a == b) {}}$", // Comparing boolean a to int b
        "{ int a { stringa a=\"exzackly\" print(a) } a=\"should fail\" print(a) }$", // Assigning "should fail" to int a
        "{intaa=4booleanbb=truebooleancstringdd=\"thereisnospoon\"c=(d!=\"thereisaspoon\")if(c==(false!=(b==(true==(a==3+1))))){print((b!=d))}}$" // Nested boolean expressions; comparing boolean b to string d
    ]
    
    private static func testSemanticAnalyzing() {
        for test in semanticAnalyzingTests {
            print(test + "\n")
            let tokens = Lexer.lex(program: test, verbose: true)!
            let AST = Parser.parse(tokens: tokens, verbose: true)!
            _ = SemanticAnalyzer.analyze(AST: AST, verbose: true)
            print()
        }
    }
    
    private static let codeGeneratingTests = [
        "{/*exzackly7*/string a a=\"exzackly\" int b b = 7 print(a) print(b)}$", // exzackly7
        "{/*truetruefalsetrue*/boolean a boolean b a=true b=a print(a) print(b) a=false print(a) print(b)}$", // truetruefalsetrue
        "{/*za7ck21*/intzz=7+7+7print(\"za\")print(3+4)print(\"ck\")print(z)}$", // za7ck21
        "{/*587810*/int a int b a = 7 { int a a = 5 print(a) b = 3+a print(b) } print(a) print(b) b = 3+a print(b) }$", // 587810
        "{/*truefalsetruefalse*/stringaa=\"yes\"print((\"yes\"==\"yes\"))print((\"yes\"==\"no\"))print((a==\"yes\"))print((a==\"no\"))}$", //compare strings
        "{/*truefalse*/stringastringba=\"yes\"b=\"yes\"print((a==b))b=\"no\"print((a==b))}$", //more compare strings
        "{/*565*/intaa=5{print(a)intaa=6print(a)}print(a)}$",
        "{/*012done*/intaa=0while(a!=3){print(a)a=1+a}print(\"done\")}$",
        "{/*onethree*/ int a a = 3 if (a==3) { print(\"one\") if (a==5) { print(\"two\") } a = 2+a if (a==5) { print(\"three\") } } }$"
    ]
    
    private static func testCodeGenerating() {
        for test in codeGeneratingTests {
            print(test + "\n")
            EXZLER.compile(input: test, verbose: true)
            print()
        }
    }
    
}
