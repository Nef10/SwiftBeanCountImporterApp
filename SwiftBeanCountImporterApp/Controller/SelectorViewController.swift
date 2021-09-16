//
//  SelectorViewController.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2017-08-28.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Cocoa
import SwiftBeanCountImporter
import SwiftBeanCountModel
import SwiftUI

enum ImportMode: Equatable {
    case csv(URL) // import file URL
    case text(String, String) // transaction, balance
    case download(String) // importer name
}

class CheckBoxTableViewCell: NSTableCellView {

    @IBOutlet private var checkBox: NSButton!

    func setUpButtonFor(row: Int, target: SelectorViewController) {
        let importer = ImporterFactory.downloadImporterNames[row]
        checkBox.title = importer
        checkBox.tag = row
        checkBox.state = target.isDownloaderImporterEnabled(row: row) ? .on : .off
        checkBox.target = target
        checkBox.action = #selector(SelectorViewController.downloderCheckBoxClicked)
    }

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
    @IBOutlet private var downloaderTableView: NSTableView!

    override func viewDidLoad() {
        updateLabel()
        super.viewDidLoad()
    }

    @IBAction private func resetButtonClicked(_ sender: Any) {
        imports = []
        updateLabel()
        downloaderTableView.reloadData()
    }

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

    @IBSegueAction
    func prepareShowHelp(_ coder: NSCoder) -> NSViewController? {
        NSHostingController(coder: coder, rootView: HelpView())
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

    @objc
    func downloderCheckBoxClicked(sender: NSButton) {
        if sender.state == .on && !isDownloaderImporterEnabled(row: sender.tag) {
            enableDownloader(row: sender.tag)
        } else if sender.state == .off && isDownloaderImporterEnabled(row: sender.tag) {
            disableDownloader(row: sender.tag)
        }
    }

    func isDownloaderImporterEnabled(row: Int) -> Bool {
        imports.contains(ImportMode.download(ImporterFactory.downloadImporterNames[row]))
    }

    private func enableDownloader(row: Int) {
        imports.append(ImportMode.download(ImporterFactory.downloadImporterNames[row]))
    }

    private func disableDownloader(row: Int) {
        imports.removeAll { $0 == ImportMode.download(ImporterFactory.downloadImporterNames[row]) }
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
        let texts = imports.filter {
            if case .text = $0 {
                return true
            }
            return false
        }.count
        fileNameLabel.stringValue = "\(files) File(s) and \(texts) text(s) added"
    }

    private func isInputValid() -> Bool {
        !imports.isEmpty
    }

    private func showValidationError() {
        showError("Please select file(s), enter valid text or select a download option.")
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

extension SelectorViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("CheckboxCell"), owner: self) as? CheckBoxTableViewCell else {
            return nil
        }
        cell.setUpButtonFor(row: row, target: self)
        return cell
    }

}

extension SelectorViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        ImporterFactory.downloadImporterNames.count
    }

}
