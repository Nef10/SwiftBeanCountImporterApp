//
//  DescriptionMappingViewController.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2019-12-25.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation
import SwiftBeanCountImporter

class DescriptionMappingViewController: NSViewController {

    private class Line: NSObject {
        @objc dynamic let importedDescription: String
        @objc dynamic let payee: String
        @objc dynamic let newDescription: String

        init(importedDescription: String, payee: String, description: String) {
            self.importedDescription = importedDescription
            self.payee = payee
            self.newDescription = description
        }
    }

    private var lines: [Line] = []

    @IBOutlet private var tableView: NSTableView!

    override func viewWillAppear() {
        refreshData()
        super.viewWillAppear()
    }

    @IBAction private func editPayee(_ sender: NSTextField) {
        let row = tableView.row(for: sender)
        let line = lines[row]
        Settings.setPayeeMapping(key: line.importedDescription, payee: sender.stringValue)
        refreshData()
    }

    @IBAction private func editDescription(_ sender: NSTextField) {
        let row = tableView.row(for: sender)
        let line = lines[row]
        Settings.setDescriptionMapping(key: line.importedDescription, description: sender.stringValue)
        refreshData()
    }

    @IBAction private func segmentControlPressed(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 { // +
            guard let newDescription = newLineAlert() else {
                return
            }
            Settings.setDescriptionMapping(key: newDescription, description: "")
            Settings.setPayeeMapping(key: newDescription, payee: "")
            refreshData()
            let index = lines.firstIndex {
                $0.importedDescription == newDescription
            }
            guard let index1 = index else {
                return
            }
            let indexSet = IndexSet(integer: index1)
            tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
            tableView.scrollRowToVisible(index1)
        } else if sender.selectedSegment == 1 {// -
            let row = tableView.selectedRow
            guard row != -1 else {
                return
            }
            let line = lines[row]
            Settings.setDescriptionMapping(key: line.importedDescription, description: nil)
            Settings.setPayeeMapping(key: line.importedDescription, payee: nil)
            refreshData()
        }
    }

    private func newLineAlert() -> String? {
        let alert = NSAlert()

        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Please enter the imported description text"
        alert.informativeText = ""

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = ""

        alert.accessoryView = textField
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            return textField.stringValue
        }
        return nil
    }

    private func refreshData() {
        let payees = Settings.allPayeeMappings
        let descriptions = Settings.allDescriptionMappings
        let array = Array(payees.keys)
        lines = array.map { Line(importedDescription: $0, payee: payees[$0] ?? "", description: descriptions[$0] ?? "") }
        lines = (lines as NSArray).sortedArray(using: tableView.sortDescriptors) as! [Line] // swiftlint:disable:this force_cast legacy_objc_type
        tableView.reloadData()
    }

}

extension DescriptionMappingViewController: NSTableViewDataSource {

    func numberOfRows(in _: NSTableView) -> Int {
        lines.count
    }

    func tableView(_: NSTableView, sortDescriptorsDidChange _: [NSSortDescriptor]) {
        refreshData()
    }

}

extension DescriptionMappingViewController: NSTableViewDelegate {

    private enum CellIdentifiers {
        static let ImportedDescriptionCell = NSUserInterfaceItemIdentifier("ImportedDescriptionCellID")
        static let PayeeCell = NSUserInterfaceItemIdentifier("PayeeCellID")
        static let DescriptionCell = NSUserInterfaceItemIdentifier("DescriptionCellID")
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        let item = lines[row]

        var text: String = ""
        var cellIdentifier: NSUserInterfaceItemIdentifier

        if tableColumn == tableView.tableColumns[0] {
            text = item.importedDescription
            cellIdentifier = CellIdentifiers.ImportedDescriptionCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = item.payee
            cellIdentifier = CellIdentifiers.PayeeCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = item.newDescription
            cellIdentifier = CellIdentifiers.DescriptionCell
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
