//
//  SelectorViewController.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-08-28.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Cocoa
import SwiftBeanCountModel

enum ImportMode {
    case csv(URL) // import file URL
    case text(String, String) // transaction, balance
}

class SelectorViewController: NSViewController {

    enum SegueIdentifier {
        static let showImport = "showImport"
        static let showTextEntry = "showTextEntry"
    }

    private var ledgerURL: URL?
    private var selectedImportMode: ImportMode?

    @IBOutlet private var fileNameLabel: NSTextField!
    @IBOutlet private var ledgerNameLabel: NSTextField!

    @IBAction private func selectButtonClicked(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["csv"]
        openPanel.begin { [weak self] response in
            if response == .OK {
                guard let fileURL = openPanel.url else {
                    return
                }
                self?.selectedImportMode = .csv(fileURL)
                self?.fileNameLabel.stringValue = fileURL.lastPathComponent
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
            controller.importMode = selectedImportMode
            if let ledgerURL = ledgerURL {
                controller.ledgerURL = ledgerURL
            }
        case SegueIdentifier.showTextEntry:
            guard let controller = segue.destinationController as? TextEntryViewController else {
                return
            }
            controller.delegate = self
            if case let .text(transactionString, balanceString)? = selectedImportMode {
                controller.prefilledTransactionString = transactionString
                controller.prefilledBalanceString = balanceString
            }
        default:
            break
        }
    }

    private func isInputValid() -> Bool {
        selectedImportMode != nil
    }

    private func showValidationError() {
        showValidationError("Please select a file or enter valid text.")
    }

    private func showValidationError(_ text: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.messageText = text
        alert.beginSheetModal(for: view.window!, completionHandler: nil)
    }

}

extension SelectorViewController: TextEntryViewControllerDelegate {

    internal func finished(_ sheet: NSWindow, transaction: String, balance: String) {
        view.window?.endSheet(sheet)
        let transactionString = transaction.trimmingCharacters(in: .whitespacesAndNewlines)
        let balanceString = balance.trimmingCharacters(in: .whitespacesAndNewlines)
        if !transactionString.isEmpty || !balanceString.isEmpty {
            selectedImportMode = .text(transactionString, balanceString)
            fileNameLabel.stringValue = "Text entered"
        } else {
            selectedImportMode = nil
            fileNameLabel.stringValue = ""
        }
    }

    func cancel(_ sheet: NSWindow) {
        view.window?.endSheet(sheet)
    }

}
