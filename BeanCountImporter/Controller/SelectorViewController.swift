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
    private var imports = [ImportMode]()

    @IBOutlet private var fileNameLabel: NSTextField!
    @IBOutlet private var ledgerNameLabel: NSTextField!

    @IBAction private func selectButtonClicked(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = true
        openPanel.allowedFileTypes = ["csv"]
        openPanel.begin { [weak self] response in
            if response == .OK {
                self?.selectFilesFromURLs(openPanel.urls)
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
            controller.imports = imports
            if let ledgerURL = ledgerURL {
                controller.ledgerURL = ledgerURL
            }
        case SegueIdentifier.showTextEntry:
            guard let controller = segue.destinationController as? TextEntryViewController else {
                return
            }
            controller.delegate = self
        default:
            break
        }
    }

    private func selectFilesFromURLs(_ urls: [URL]) {
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
        for url in urls {
            if !url.hasDirectoryPath {
                imports.append(.csv(url))
            } else {
                let enumerator = FileManager.default.enumerator(at: url,
                                                                includingPropertiesForKeys: resourceKeys,
                                                                options: [.skipsHiddenFiles]) { _, error -> Bool in
                                                                    self.showError(error.localizedDescription)
                                                                    return true
                }!
                for case let fileURL as URL in enumerator where !fileURL.hasDirectoryPath && fileURL.pathExtension.lowercased() == "csv" {
                    imports.append(.csv(url))
                }
            }
        }
        updateLabel()
    }

    private func updateLabel() {
        let files = imports.filter {
            if case .csv = $0 {
                return true
            }
            return false
        }.count
        let texts = imports.count - files
        fileNameLabel.stringValue = "\(files) File(s) and \(texts) text(s) added"
    }

    private func isInputValid() -> Bool {
        !imports.isEmpty
    }

    private func showValidationError() {
        showError("Please select file(s) or enter valid text.")
    }

    private func showError(_ text: String) {
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
            imports.append(.text(transactionString, balanceString))
            updateLabel()
        }
    }

    func cancel(_ sheet: NSWindow) {
        view.window?.endSheet(sheet)
    }

}
