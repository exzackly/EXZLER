//
//  Tester.swift
//  EXZLER
//
//  Created by EXZACKLY on 2/6/18.
//

import Foundation

class Tester {
    
    private static let tests = [
        /* fail lex */
        "{int @}$", // Invalid @
        "{int \n@\n}$", // Invalid @
        "{ print(\"invalid @\")}$", // Invalid token in string
        "{ print(\"invalid 7\")}$", // Digit invalid in string
        /* fail parse */
        "{{{{{{}}} /* comments are ignored */ }}}}$", // Unmatched braces
        "{if (a == c+7) {}}$", // id+digit is invalid
        /* fail semantic analysis */
        "{boolean a a = true int b b = 7 if (a == b) {}}$", // Comparing boolean a to int b
        "{ int a { stringa a=\"exzackly\" print(a) } a=\"should fail\" print(a) }$", // Assigning "should fail" to int a
        "{intaa=4booleanbb=truebooleancstringdd=\"thereisnospoon\"c=(d!=\"thereisaspoon\")if(c==(false!=(b==(true==(a==3+1))))){print((b!=d))}}$", // Nested boolean expressions; comparing boolean b to string d
        /* compile */
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
    
    static func testEXZLER() {
        for test in tests {
            EXZLER.compile(input: test, verbose: true)
            print()
        }
    }
    
}
