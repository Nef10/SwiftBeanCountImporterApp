//
//  ViewController.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-08-28.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Cocoa
import CSV
import SwiftBeanCountModel
import SwiftBeanCountParser

class SelectorViewController: NSViewController {

    struct SegueIdentifier {
        static let showImport = "showImport"
    }

    @IBOutlet private weak var accountNameField: NSTextField!
    @IBOutlet private weak var commoditySymbolField: NSTextField!
    @IBOutlet private weak var fileNameLabel: NSTextField!
    @IBOutlet private weak var ledgerNameLabel: NSTextField!

    private var fileURL: URL?
    private var ledgerURL: URL?

    @IBAction private func selectButtonClicked(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["csv"]
        openPanel.begin { [weak self] response in
            if response == .OK {
                self?.fileURL = openPanel.url
                self?.fileNameLabel.stringValue = self?.fileURL?.lastPathComponent ?? ""
            }
        }
    }

    @IBAction private func ledgerSelectButtonClicked(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["beancount"]
        openPanel.begin { [weak self] response in
            if response == .OK {
                self?.ledgerURL = openPanel.url
                self?.ledgerNameLabel.stringValue = self?.ledgerURL?.lastPathComponent ?? ""
            }
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: NSStoryboardSegue.Identifier, sender: Any?) -> Bool {
        switch identifier {
        case SegueIdentifier.showImport:
            if !isInputValid() {
                showValidationError()
                return false
            }
            return true
        default:
            return true
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case SegueIdentifier.showImport:
            guard let controller = segue.destinationController as? ImportViewController else {
                return
            }
            controller.csvImporter = CSVImporter.new(url: fileURL, accountName: accountNameField.stringValue, commoditySymbol: commoditySymbolField.stringValue)
            if let ledgerURL = ledgerURL {
                controller.autocompleteLedger = try? Parser.parse(contentOf: ledgerURL)
            }
        default:
            break
        }
    }

    private func isInputValid() -> Bool {
        return isFileValid() && isAccountValid() && isCommodityValid()
    }

    private func isFileValid() -> Bool {
        return fileURL != nil
    }

    private func isAccountValid() -> Bool {
        return Account.isNameValid(accountNameField.stringValue)
    }

    private func isCommodityValid() -> Bool {
        return !commoditySymbolField.stringValue.isEmpty
    }

    private func showValidationError() {
        if !isFileValid() {
            showValidationError("Please select a file.")
        } else if !isAccountValid() {
            showValidationError("Please enter a valid account.")
        } else if !isCommodityValid() {
            showValidationError("Please enter a Commodity.")
        }
    }

    private func showValidationError(_ text: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.messageText = text
        alert.beginSheetModal(for: view.window!, completionHandler: nil)
    }

}
