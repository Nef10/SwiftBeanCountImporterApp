//
//  ImportViewController.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2017-09-03.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Cocoa
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
        textView.string = ("\(resultLedger.transactions.sorted { $0.metaData.date < $1.metaData.date }.map { "\($0)" }.joined(separator: "\n\n"))\n\n" +
            "\(resultLedger.accounts.flatMap { $0.balances }.sorted { $0.date < $1.date }.map { "\($0)" }.joined(separator: "\n"))\n\n" +
            "\(resultLedger.prices.sorted { $0.date < $1.date }.map { "\($0)" }.joined(separator: "\n"))")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
            guard let self = self else {
                return
            }
            for importMode in self.imports {
                switch importMode {
                case let .csv(fileURL):
                    guard let importer = ImporterFactory.new(ledger: self.ledger, url: fileURL) else {
                        self.errors.append("Unable to find importer for: \(fileURL)")
                        continue
                    }
                    self.importers.append(importer)
                case let .text(transaction, balance):
                    guard let importer = ImporterFactory.new(ledger: self.ledger, transaction: transaction, balance: balance) else {
                        self.errors.append("Unable to find importer for text: \(transaction) \(balance)")
                        continue
                    }
                    self.importers.append(importer)
                }
            }
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.loadingIndicatorSheet), sender: self)
            self.loadingIndicatorSheet?.updateText(text: "Preparing import \(self.currentImporter.importName)")
            DispatchQueue.global(qos: .userInitiated).async {
                self.currentImporter.load()
                DispatchQueue.main.async { [weak self] in
                    if let window = self?.loadingIndicatorSheet?.view.window {
                        self?.view.window?.endSheet(window)
                    }
                    self?.showDataEntryViewForNextTransactionIfNeccessary()
                }
            }
        }
    }

    private func showDataEntryViewForNextTransactionIfNeccessary() {
        nextTransaction = currentImporter.nextTransaction()
        if let importedTransaction = nextTransaction {
            if importedTransaction.shouldAllowUserToEdit {
                showDataEntryOrDuplicateTransactionViewForTransaction()
            } else {
                resultLedger.add(importedTransaction.transaction)
                updateOutput()
                showDataEntryViewForNextTransactionIfNeccessary()
            }
        } else {
            for balance in currentImporter.balancesToImport() {
                resultLedger.add(balance)
            }
            for price in currentImporter.pricesToImport() {
                try? resultLedger.add(price)
            }
            updateOutput()
            nextImporter()
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
        performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.dataEntrySheet), sender: self)
    }

    private func showDuplicateTransactionViewForTransaction() {
        performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.duplicateTransactionSheet), sender: self)
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

    func requestInput(name: String, suggestions: [String], allowSaving: Bool, allowSaved: Bool, completion: @escaping (String) -> Bool) {
        inputRequest = (name, suggestions, false, completion)
        showInputRequest()
    }

    func requestSecretInput(name: String, allowSaving: Bool, allowSaved: Bool, completion: @escaping (String) -> Bool) {
        inputRequest = (name, [], true, completion)
        showInputRequest()
    }

}
