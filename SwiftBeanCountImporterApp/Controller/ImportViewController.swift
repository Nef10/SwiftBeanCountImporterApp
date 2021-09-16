//
//  ImportViewController.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2017-09-03.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Cocoa
import KeychainAccess
import SwiftBeanCountImporter
import SwiftBeanCountModel
import SwiftBeanCountParser

class ImportViewController: NSViewController {

    enum SegueIdentifier {
        static let dataEntrySheet = "dataEntrySheet"
        static let duplicateTransactionSheet = "duplicateTransactionSheet"
        static let loadingIndicatorSheet = "loadingIndicatorSheet"
        static let importerInputSheet = "importerInputSheet"
    }

    var imports = [ImportMode]()
    var ledgerURL: URL?

    private  let keychain = Keychain(service: "com.github.nef10.swiftbeancountimporterapp")

    private var ledger: Ledger?
    private var resultLedger: Ledger = Ledger()
    private var nextTransaction: ImportedTransaction?
    private var importers = [Importer]()
    private var currentImporter: Importer!
    private var errors = [String]()
    private var inputRequest: (String, [String], Bool, (String) -> Bool)! // swiftlint:disable:this large_tuple

    private weak var loadingIndicatorSheet: LoadingIndicatorViewController?

    @IBOutlet private var textView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.processPassedData {
                self?.handleInvalidPassedData {
                    self?.nextImporter()
                }
            }
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) { // swiftlint:disable:this function_body_length
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case SegueIdentifier.dataEntrySheet:
            guard let controller = segue.destinationController as? DataEntryViewController else {
                return
            }
            controller.importedTransaction = nextTransaction
            controller.delegate = self
            controller.ledger = ledger
        case SegueIdentifier.duplicateTransactionSheet:
            guard let controller = segue.destinationController as? DuplicateTransactionViewController else {
                return
            }
            controller.importedTransaction = nextTransaction?.transaction
            controller.existingTransaction = nextTransaction?.possibleDuplicate
            controller.importName = currentImporter.importName
            controller.delegate = self
        case SegueIdentifier.loadingIndicatorSheet:
            guard let controller = segue.destinationController as? LoadingIndicatorViewController else {
                return
            }
            loadingIndicatorSheet = controller
        case SegueIdentifier.importerInputSheet:
            guard let controller = segue.destinationController as? ImporterInputViewController else {
                return
            }
            if let window = self.loadingIndicatorSheet?.view.window {
                self.view.window?.endSheet(window)
            }
            let (name, suggestions, isSecure, _) = inputRequest
            controller.delegate = self
            controller.suggestions = suggestions
            controller.importName = currentImporter.importName
            controller.name = name
            controller.isSecure = isSecure
        default:
            break
        }
    }

    private func updateOutput() {
        DispatchQueue.main.async {
            self.textView.string = ("\(self.resultLedger.transactions.sorted { $0.metaData.date < $1.metaData.date }.map { "\($0)" }.joined(separator: "\n\n"))\n\n" +
                                    "\(self.resultLedger.accounts.flatMap { $0.balances }.sorted { $0.date < $1.date }.map { "\($0)" }.joined(separator: "\n"))\n\n" +
                                    "\(self.resultLedger.prices.sorted { $0.date < $1.date }.map { "\($0)" }.joined(separator: "\n"))")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func loadLedger(completion: @escaping () -> Void) {
        if let ledgerURL = ledgerURL {
            DispatchQueue.main.async { [weak self] in
                self?.loadingIndicatorSheet?.updateText(text: "Loading Ledger")
            }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.ledger = try? Parser.parse(contentOf: ledgerURL)
                completion()
            }
        } else {
            completion()
        }
    }

    private func setupImporter(completion: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.loadingIndicatorSheet?.updateText(text: "Preparing imports")
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.importers = self?.imports.compactMap {
                switch $0 {
                case let .csv(fileURL):
                    if let importer = ImporterFactory.new(ledger: self?.ledger, url: fileURL) {
                        return importer
                    }
                    self?.errors.append("Unable to find importer for: \(fileURL)")
                case let .text(transaction, balance):
                    if let importer = ImporterFactory.new(ledger: self?.ledger, transaction: transaction, balance: balance) {
                        return importer
                    }
                    self?.errors.append("Unable to find importer for text: \(transaction) \(balance)")
                case let .download(name):
                    guard let ledger = self?.ledger else {
                        self?.errors.append("Downloads require a ledger to be selected.")
                        return nil
                    }
                    if let importer = ImporterFactory.new(ledger: ledger, name: name) {
                        return importer
                    }
                    self?.errors.append("Unable to find importer for download: \(name)")
                }
                return nil
            } ?? []
            completion()
        }
    }

    private func processPassedData(completion: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.loadingIndicatorSheet), sender: self)
        }
        loadLedger { [weak self] in
            self?.setupImporter { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    guard let window = self?.loadingIndicatorSheet?.view.window else {
                        return
                    }
                    self?.view.window?.endSheet(window)
                }
                completion()
            }
        }
    }

    private func setupUI() {
        if let font = NSFont(name: "Menlo", size: 12) {
            textView.typingAttributes = [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: NSColor.controlTextColor
            ]
        }
    }

    private func handleInvalidPassedData(completion: @escaping (() -> Void)) {
        if errors.isEmpty {
            if importers.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    self?.textView.string = "Unable to import data"
                }
            }
            completion()
        } else {
            let error = errors.popLast()!
            DispatchQueue.main.async { [weak self] in
                self?.showError(error) { _ in
                    self?.handleInvalidPassedData(completion: completion)
                }
            }
        }

    }

    private func nextImporter() {
        currentImporter = importers.popLast()
        if currentImporter != nil {
            currentImporter.delegate = self
            importData()
        }
    }

    private func importData() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.loadingIndicatorSheet), sender: self)
            self.loadingIndicatorSheet?.updateText(text: "Preparing import \(self.currentImporter.importName)")
            DispatchQueue.global(qos: .userInitiated).async {
                self.currentImporter.load()
                DispatchQueue.main.async {
                    if let window = self.loadingIndicatorSheet?.view.window {
                        self.view.window?.endSheet(window)
                    }
                }
                self.showDataEntryViewForNextTransactionIfNeccessary()
            }
        }
    }

    private func showDataEntryViewForNextTransactionIfNeccessary() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.nextTransaction = self.currentImporter.nextTransaction()
            if let importedTransaction = self.nextTransaction {
                if importedTransaction.shouldAllowUserToEdit {
                    self.showDataEntryOrDuplicateTransactionViewForTransaction()
                } else {
                    self.resultLedger.add(importedTransaction.transaction)
                    self.updateOutput()
                    self.showDataEntryViewForNextTransactionIfNeccessary()
                }
            } else {
                for balance in self.currentImporter.balancesToImport() {
                    self.resultLedger.add(balance)
                }
                for price in self.currentImporter.pricesToImport() {
                    try? self.resultLedger.add(price)
                }
                self.updateOutput()
                self.nextImporter()
            }
        }
    }

    private func showDataEntryOrDuplicateTransactionViewForTransaction() {
        if nextTransaction?.possibleDuplicate != nil {
            showDuplicateTransactionViewForTransaction()
        } else {
            showDataEntryViewForTransaction()
        }
    }

    private func showDataEntryViewForTransaction() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.dataEntrySheet), sender: self)
        }
    }

    private func showDuplicateTransactionViewForTransaction() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.duplicateTransactionSheet), sender: self)
        }
    }

    private func showError(_ error: String, completion: ((NSApplication.ModalResponse) -> Void)?) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.messageText = error
        alert.beginSheetModal(for: view.window!, completionHandler: completion)
    }

    private func showInputRequest() {
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.importerInputSheet), sender: self)
        }
    }

}

extension ImportViewController: DataEntryViewControllerDelegate, DuplicateTransactionViewControllerDelegate, ImporterInputViewControllerDelegate {

    func finished(_ sheet: NSWindow, transaction: Transaction) {
        view.window?.endSheet(sheet)
        resultLedger.add(transaction)
        updateOutput()
        showDataEntryViewForNextTransactionIfNeccessary()
    }

    func finished(_ sheet: NSWindow, input: String) {
        view.window?.endSheet(sheet)
        let (_, _, _, completion) = inputRequest
        if !completion(input) {
            showInputRequest()
        }
    }

    func cancel(_ sheet: NSWindow) {
        view.window?.endSheet(sheet)
        view.window?.close()
    }

    func skipImporting(_ sheet: NSWindow) {
        view.window?.endSheet(sheet)
        showDataEntryViewForNextTransactionIfNeccessary()
    }

    func importAnyway(_ sheet: NSWindow) {
        view.window?.endSheet(sheet)
        showDataEntryViewForTransaction()
    }

}

extension ImportViewController: ImporterDelegate {

    func requestInput(name: String, suggestions: [String], isSecret: Bool, completion: @escaping (String) -> Bool) {
        inputRequest = (name, suggestions, isSecret, completion)
        showInputRequest()
    }

    func saveCredential(_ value: String, for key: String) {
        keychain[key] = value
    }

    func readCredential(_ key: String) -> String? {
        keychain[key]
    }

    func error(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.showError(error.localizedDescription) { _ in
                if self?.currentImporter != nil {
                    self?.showDataEntryViewForNextTransactionIfNeccessary()
                }
            }
        }
    }

}
