//
//  EXZLERInputViewController.swift
//  EXZLER
//
//  Created by EXZACKLY on 5/6/18.
//  Copyright © 2018 EXZACKLY. All rights reserved.
//

import UIKit

class EXZLERInputViewController: UIViewController {
    
    @IBOutlet var codeTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    let samplePrograms = [
        "{/*exzackly7*/\n string a\n a=\"exzackly\"\n int b\n b = 7\n print(a)\n print(b)\n}$", // exzackly7
        "{/*za7ck21*/\n int z\n z=7+7+7\n print(\"za\")\n print(3+4)\n print(\"ck\")\n print(z)\n}$", // za7ck21
        "{/*12done*/\n int a\n a=1\n while(a!=3){\n \tprint(a)\n \ta=1+a\n }\n print(\"done\")\n}$",
        "{/*truefalsetruefalse*/\n string a\n a=\"yes\"\n print((\"yes\"==\"yes\"))\n print((\"yes\"==\"no\"))\n print((a==\"yes\"))\n print((a==\"no\"))\n}$", //compare strings
        "{/*onethree*/\n int a\n a = 3\n if (a==3) {\n \tprint(\"one\")\n \tif (a==5) {\n \t\tprint(\"two\")\n \t}\n \ta = 2+a\n \tif (a==5) {\n \t\tprint(\"three\")\n \t}\n }\n}$"
    ]
    
    @IBAction func loadSample(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Select a sample program", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = sender
        alert.addAction(UIAlertAction(title: "exzackly7", style: .default, handler: { _ in self.codeTextView.text = self.samplePrograms[0] }))
        alert.addAction(UIAlertAction(title: "za7ck21", style: .default, handler: { _ in self.codeTextView.text = self.samplePrograms[1] }))
        alert.addAction(UIAlertAction(title: "12done", style: .default, handler: { _ in self.codeTextView.text = self.samplePrograms[2] }))
        alert.addAction(UIAlertAction(title: "truefalsetruefalse (compare strings)", style: .default, handler: { _ in self.codeTextView.text = self.samplePrograms[3] }))
        alert.addAction(UIAlertAction(title: "onethree (branching)", style: .default, handler: { _ in self.codeTextView.text = self.samplePrograms[4] }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var data = [[String](),[String](),[String](),[String]()] // Lex, parse, semantic analysis, code generation
        var index = 0
        let emit: (String, String, String) -> () = { (prefix, delimiter, message) in
            let messageType = ["LEXER" : 0, "PARSER" : 1, "SEMANTIC ANALYZER" : 2, "CODE GENERATOR" : 3][prefix]
            index = messageType ?? index
            data[index].append(messageType != nil ? message : prefix+message)
        }
        EXZLER.compile(input: codeTextView.text!, verbose: true, emit: emit)
        let destinationViewController = segue.destination as! EXZLEROutputTableViewController
        destinationViewController.data = data
    }

}
