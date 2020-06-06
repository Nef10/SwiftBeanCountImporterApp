//
//  ImportersViewController.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-10.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation
import SwiftBeanCountImporter

class ImportersViewController: NSViewController {

    private let importers = ImporterManager.importers
    private var selectedImporter: Importer.Type?

    @IBOutlet private var importersTableView: NSTableView!
    @IBOutlet private var settingsTableView: NSTableView!

    override func viewWillAppear() {
        importersTableView.reloadData()
        settingsTableView.reloadData()
        super.viewWillAppear()
    }

    @IBAction private func editValue(_ sender: NSTextField) {
        guard let importer = selectedImporter else {
            return
        }
        let row = settingsTableView.row(for: sender)
        importer.set(setting: importer.settings[row], to: sender.stringValue)
    }

}

extension ImportersViewController: NSTableViewDelegate {

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let table = notification.object as? NSTableView else {
            return
        }
        if table == importersTableView {
            if importersTableView.selectedRow == -1 {
                selectedImporter = nil
            } else {
                selectedImporter = importers[importersTableView.selectedRow]
            }
            settingsTableView.reloadData()
        }
    }

}

extension ImportersViewController: NSTableViewDataSource {

    private enum CellIdentifiers {
        static let NameCell = NSUserInterfaceItemIdentifier("NameCellID")
        static let SettingCell = NSUserInterfaceItemIdentifier("SettingCellID")
        static let ValueCell = NSUserInterfaceItemIdentifier("ValueCellID")
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == importersTableView {
            return ImporterManager.importers.count
        } else if tableView == settingsTableView {
            guard let selectedImporter = selectedImporter else {
                return 0
            }
            return selectedImporter.settings.count
        }
        return 0
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        var cellIdentifier: NSUserInterfaceItemIdentifier?
        var text: String = ""

        if tableView == importersTableView {
            let importer = importers[row]

            if tableColumn == tableView.tableColumns[0] {
                text = importer.settingsName
                cellIdentifier = CellIdentifiers.NameCell
            } else {
                return nil
            }
        } else if tableView == settingsTableView {
            guard let selectedImporter = selectedImporter else {
                return nil
            }
            let setting = selectedImporter.settings[row]
            if tableColumn == tableView.tableColumns[0] {
                text = setting.name
                cellIdentifier = CellIdentifiers.SettingCell
            } else if tableColumn == tableView.tableColumns[1] {
                text = selectedImporter.get(setting: setting) ?? ""
                cellIdentifier = CellIdentifiers.ValueCell
            } else {
                return nil
            }
        }

        guard let identifier = cellIdentifier else {
            return nil
        }
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }

        return nil
    }

}
