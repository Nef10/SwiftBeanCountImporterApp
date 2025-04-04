//
//  AccountMappingViewController.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-15.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation
import SwiftBeanCountImporter

class AccountMappingViewController: NSViewController {

    private class Line: NSObject {
        @objc dynamic let payee: String
        @objc dynamic let account: String

        init(payee: String, account: String) {
            self.payee = payee
            self.account = account
        }
    }

    private var lines: [Line] = []

    @IBOutlet private var tableView: NSTableView!

    override func viewWillAppear() {
        refreshData()
        super.viewWillAppear()
    }

    @IBAction private func editAccount(_ sender: NSTextField) {
        let row = tableView.row(for: sender)
        let line = lines[row]
        Settings.setAccountMapping(key: line.payee, account: sender.stringValue)
        refreshData()
    }

    @IBAction private func segmentControlPressed(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 { // +
            guard let newPayee = newLineAlert() else {
                return
            }
            Settings.setAccountMapping(key: newPayee, account: "")
            refreshData()
            let index = lines.firstIndex {
                $0.payee == newPayee
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
            Settings.setAccountMapping(key: line.payee, account: nil)
            refreshData()
        }
    }

    private func newLineAlert() -> String? {
        let alert = NSAlert()

        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Please enter the payee"
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
        let accounts = Settings.allAccountMappings
        let array = Array(accounts.keys)
        lines = array.map { Line(payee: $0, account: accounts[$0] ?? "") }
        lines = (lines as NSArray).sortedArray(using: tableView.sortDescriptors) as! [Line] // swiftlint:disable:this force_cast legacy_objc_type
        tableView.reloadData()
    }

}

extension AccountMappingViewController: NSTableViewDataSource {

    func numberOfRows(in _: NSTableView) -> Int {
        lines.count
    }

    func tableView(_: NSTableView, sortDescriptorsDidChange _: [NSSortDescriptor]) {
        refreshData()
    }

}

extension AccountMappingViewController: NSTableViewDelegate {

    private enum CellIdentifiers {
        static let PayeeCell = NSUserInterfaceItemIdentifier("PayeeCellID")
        static let AccountCell = NSUserInterfaceItemIdentifier("AccountCellID")
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        let item = lines[row]

        var text: String = ""
        var cellIdentifier: NSUserInterfaceItemIdentifier

        if tableColumn == tableView.tableColumns[0] {
            text = item.payee
            cellIdentifier = CellIdentifiers.PayeeCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = item.account
            cellIdentifier = CellIdentifiers.AccountCell
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
