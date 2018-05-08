//
//  EXZLEROutputTableViewController.swift
//  EXZLER
//
//  Created by EXZACKLY on 5/6/18.
//  Copyright © 2018 EXZACKLY. All rights reserved.
//

import UIKit

class EXZLEROutputTableViewController: UITableViewController {

    var data: [[String]]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func jumpToCode(_ sender: UIBarButtonItem) {
        let indexPath = IndexPath(row: data[3].count-1, section: 3)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = data[indexPath.section][indexPath.row].trimmingCharacters(in: .whitespacesAndNewlines)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIPasteboard.general.string = data[indexPath.section][indexPath.row]
        let alert = UIAlertController(title: "Text copied", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let share = UITableViewRowAction(style: .normal, title: "Share") { _,indexPath in
            let activityViewController = UIActivityViewController(activityItems: [ self.data[indexPath.section][indexPath.row] ], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
            self.present(activityViewController, animated: true, completion: nil)
        }
        share.backgroundColor = .blue
        return [share]
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return [0: "LEXER", 1: "PARSER", 2: "SEMANTIC ANALYZER", 3: "CODE GENERATOR"][section]
    }

}
