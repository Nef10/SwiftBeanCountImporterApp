//
//  ImportersViewController.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-10.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation

class ImportersViewController: NSViewController {

    private let importers = ImporterManager.importers

    @IBOutlet private var importersTableView: NSTableView!

}

extension ImportersViewController: NSTableViewDelegate {

}

extension ImportersViewController: NSTableViewDataSource {

    private enum CellIdentifiers {
        static let NameCell = NSUserInterfaceItemIdentifier("NameCellID")
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        ImporterManager.importers.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        let importer = importers[row]

        var text: String = ""
        var cellIdentifier: NSUserInterfaceItemIdentifier

        if tableColumn == tableView.tableColumns[0] {
            text = importer.settingsName
            cellIdentifier = CellIdentifiers.NameCell
        } else {
            return nil
        }

        if let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }

        return nil
    }

}
