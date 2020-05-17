//
//  ImportViewController.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-09-03.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Cocoa
import SwiftBeanCountModel
import SwiftBeanCountParser

class ImportViewController: NSViewController {

    enum SegueIdentifier {
        static let dataEntrySheet = "dataEntrySheet"
        static let duplicateTransactionSheet = "duplicateTransactionSheet"
        static let loadingIndicatorSheet = "loadingIndicatorSheet"
        static let accountSelectionSheet = "accountSelectionSheet"
    }

    enum ImporterType {
        case file(FileImporter)
        case text(TextImporter)
    }

    private static var dateTolerance: TimeInterval {
        if let daysString = UserDefaults.standard.string(forKey: Settings.dateToleranceUserDefaultsKey), let days = Int(daysString) {
            return Double(days * 60 * 60 * 24) // X days +- to check for duplicate transaction
        }
        return Double(Settings.defaultDateTolerance * 60 * 60 * 24)
    }

    var imports = [ImportMode]()
    var ledgerURL: URL?

    private var ledger: Ledger?
    private var resultLedger: Ledger = Ledger()
    private var nextTransaction: ImportedTransaction?
    private var importers = [ImporterType]()
    private var currentImporter: ImporterType!
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

    // swiftlint:disable:next cyclomatic_complexity
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case SegueIdentifier.dataEntrySheet:
            guard let controller = segue.destinationController as? DataEntryViewController, case let .file(fileImporter) = currentImporter else {
                return
            }
            controller.baseAccount = fileImporter.account
            controller.importedTransaction = nextTransaction
            controller.delegate = self
            controller.ledger = ledger
        case SegueIdentifier.duplicateTransactionSheet:
            guard let controller = segue.destinationController as? DuplicateTransactionViewController else {
                return
            }
            controller.importedTransaction = nextTransaction?.transaction
            controller.existingTransaction = doesTransactionAlreadyExist()
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
            controller.possibleAccounts = possibleAccounts()
            if case let .file(fileImporter) = currentImporter {
                controller.fileName = fileImporter.fileName
            }
        default:
            break
        }
    }

    private func updateOutput() {
        textView.string = resultLedger.transactions.map { String(describing: $0) }.reduce(into: "") { $0.append("\n\n\($1)") }.trimmingCharacters(in: .whitespacesAndNewlines)
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
                    guard let fileImporter = FileImporterManager.new(ledger: self.ledger, url: fileURL) else {
                        self.errors.append("Unable to find importer for: \(fileURL)")
                        continue
                    }
                    fileImporter.loadFile()
                    self.importers.append(.file(fileImporter))
                case let .text(transaction, balance):
                    guard let textImporter = TextImporterManager.new(ledger: self.ledger, transaction: transaction, balance: balance) else {
                        self.errors.append("Unable to find importer for text: \(transaction) \(balance)")
                        continue
                    }
                    self.importers.append(.text(textImporter))
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
            textView.typingAttributes = [NSAttributedString.Key.font: font]
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

    private func possibleAccounts() -> [String] {
        switch currentImporter {
        case let .file(fileImporter):
            return fileImporter.possibleAccounts()
        case let .text(textImporter):
            return textImporter.possibleAccounts()
        default:
            return []
        }
    }

    private func setAccount() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            let possibleAccounts = self.possibleAccounts()
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
            switch self.currentImporter {
            case .file:
                self.showDataEntryViewForNextTransactionIfNeccessary()
            case let .text(textImporter):
                self.textView.string.append("\n\(textImporter.parse())")
                self.nextImporter()
            default:
                break
            }
        }
    }

    private func showDataEntryViewForNextTransactionIfNeccessary() {
        guard case let .file(fileImporter) = currentImporter else {
            return
        }
        nextTransaction = fileImporter.parseLineIntoTransaction()
        if nextTransaction != nil {
            showDataEntryOrDuplicateTransactionViewForTransaction()
        } else {
            nextImporter()
        }
    }

    private func showDataEntryOrDuplicateTransactionViewForTransaction() {
        if doesTransactionAlreadyExist() != nil {
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

    private func doesTransactionAlreadyExist() -> Transaction? {
        guard let nextTransaction = nextTransaction?.transaction, let ledger = ledger else {
            return nil
        }
        return ledger.transactions.first {
            $0.postings.contains { $0.account.name == nextTransaction.postings.first?.account.name && $0.amount == nextTransaction.postings.first?.amount }
                && $0.metaData.date + Self.dateTolerance >= nextTransaction.metaData.date && $0.metaData.date - Self.dateTolerance <= nextTransaction.metaData.date
        }
    }

    private func useAccount(name: String) {
        do {
            switch currentImporter {
            case let .file(fileImporter):
                try fileImporter.useAccount(name: name)
            case let .text(textImporter):
                try textImporter.useAccount(name: name)
            default:
                break
            }
        } catch {
            showError("\(error.localizedDescription)") { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.accountSelectionSheet), sender: self)
            }
            return
        }
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
        _ = resultLedger.add(transaction)
        updateOutput()
        showDataEntryViewForNextTransactionIfNeccessary()
    }

    func finished(_ sheet: NSWindow, accountName: String) {
        view.window?.endSheet(sheet)
        useAccount(name: accountName)
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
