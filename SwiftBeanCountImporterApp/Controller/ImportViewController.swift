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
        static let accountSelectionSheet = "accountSelectionSheet"
    }

    var imports = [ImportMode]()
    var ledgerURL: URL?

    private var ledger: Ledger?
    private var resultLedger: Ledger = Ledger()
    private var nextTransaction: ImportedTransaction?
    private var importers = [Importer]()
    private var currentImporter: Importer!
    private var errors = [String]()

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

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
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
        case SegueIdentifier.accountSelectionSheet:
            guard let controller = segue.destinationController as? AccountSelectionViewController else {
                return
            }
            controller.delegate = self
            controller.possibleAccounts = currentImporter.possibleAccountNames().map { $0.fullName }
            controller.importName = currentImporter.importName
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
            self?.loadingIndicatorSheet?.updateText(text: "Loading import data")
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
                    importer.load()
                    self.importers.append(importer)
                case let .text(transaction, balance):
                    guard let importer = ImporterFactory.new(ledger: self.ledger, transaction: transaction, balance: balance) else {
                        self.errors.append("Unable to find importer for text: \(transaction) \(balance)")
                        continue
                    }
                    importer.load()
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

    private func setAccount() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            let possibleAccounts = self.currentImporter.possibleAccountNames()
            if possibleAccounts.count != 1 {
                self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.accountSelectionSheet), sender: self)
            } else {
                self.useAccount(name: possibleAccounts.first!)
            }
        }
    }

    private func nextImporter() {
        currentImporter = importers.popLast()
        if currentImporter != nil {
            setAccount()
        }
    }

    private func importData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.showDataEntryViewForNextTransactionIfNeccessary()
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

    private func useAccount(name: AccountName) {
        currentImporter.useAccount(name: name)
        importData()
    }

    private func showError(_ error: String, completion: ((NSApplication.ModalResponse) -> Void)?) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.messageText = error
        alert.beginSheetModal(for: view.window!, completionHandler: completion)
    }

}

extension ImportViewController: DataEntryViewControllerDelegate, DuplicateTransactionViewControllerDelegate, AccountSelectionViewControllerDelegate {

    func finished(_ sheet: NSWindow, transaction: Transaction) {
        view.window?.endSheet(sheet)
        resultLedger.add(transaction)
        updateOutput()
        showDataEntryViewForNextTransactionIfNeccessary()
    }

    func finished(_ sheet: NSWindow, accountName: String) {
        view.window?.endSheet(sheet)
        do {
            let accountName = try AccountName(accountName)
            useAccount(name: accountName)
        } catch {
            showError("\(error.localizedDescription)") { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.accountSelectionSheet), sender: self)
            }
            return
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
