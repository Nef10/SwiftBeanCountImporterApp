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

    private static var dateTolerance: TimeInterval {
        if let daysString = UserDefaults.standard.string(forKey: Settings.dateToleranceSettingsKey), let days = Int(daysString) {
            return Double(days * 60 * 60 * 24) // X days +- to check for duplicate transaction
        }
        return Double(Settings.dateToleranceDefaultSetting * 60 * 60 * 24)
    }

    var importMode: ImportMode?
    var autocompleteLedgerURL: URL?

    private var autocompleteLedger: Ledger?
    private var resultLedger: Ledger = Ledger()
    private var nextTransaction: ImportedTransaction?
    private var fileImporter: FileImporter?
    private var textImporter: TextImporter?

    private weak var loadingIndicatorSheet: LoadingIndicatorViewController?

    @IBOutlet private var textView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.processPassedData()
            guard self?.isPassedDataValid() ?? false else {
                self?.handleInvalidPassedData()
                return
            }
            self?.setAccount()
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case SegueIdentifier.dataEntrySheet:
            guard let controller = segue.destinationController as? DataEntryViewController, case .csv = importMode else {
                return
            }
            controller.baseAccount = fileImporter?.account
            controller.importedTransaction = nextTransaction
            controller.delegate = self
            controller.ledger = autocompleteLedger
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
            if case let .csv(fileName) = importMode {
                controller.fileName = fileName.lastPathComponent
            }
        default:
            break
        }
    }

    private func updateOutput() {
        textView.string = resultLedger.transactions.map { String(describing: $0) }.reduce(into: "") { $0.append("\n\n\($1)") }.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func processPassedData() {
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.loadingIndicatorSheet), sender: self)
            self?.loadingIndicatorSheet?.updateText(text: "Loading import data")
        }
        switch importMode {
        case let .csv(fileURL)?:
            fileImporter = FileImporterManager.new(url: fileURL)
            fileImporter?.loadFile()
        case .text:
            textImporter = TextImporterManager.new(autocompleteLedger: autocompleteLedger)
        case .none:
            break
        }
        if let autocompleteLedgerURL = autocompleteLedgerURL {
            DispatchQueue.main.async { [weak self] in
                self?.loadingIndicatorSheet?.updateText(text: "Loading Ledger")
            }
            autocompleteLedger = try? Parser.parse(contentOf: autocompleteLedgerURL)
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let window = self.loadingIndicatorSheet?.view.window else {
                return
            }
            self.view.window?.endSheet(window)
        }
    }

    private func isPassedDataValid() -> Bool {
        fileImporter != nil || textImporter != nil
    }

    private func setupUI() {
        if let font = NSFont(name: "Menlo", size: 12) {
            textView.typingAttributes = [NSAttributedString.Key.font: font]
        }
    }

    private func handleInvalidPassedData() {
        DispatchQueue.main.async { [weak self] in
            self?.textView.string = "Unable to import data"
        }
    }

    private func possibleAccounts() -> [String] {
        switch importMode {
        case .csv:
            return fileImporter?.possibleAccounts() ?? []
        case .text:
            return textImporter?.possibleAccounts() ?? []
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

    private func importData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            if let textImporter = self.textImporter, case let .text(transactionString, balanceString)? = self.importMode {
                self.textView.string = textImporter.parse(transaction: transactionString, balance: balanceString)
            } else {
                self.showDataEntryViewForNextTransactionIfNeccessary()
            }
        }
    }

    private func showDataEntryViewForNextTransactionIfNeccessary() {
        guard case .csv = importMode else {
            return
        }
        nextTransaction = fileImporter?.parseLineIntoTransaction()
        if nextTransaction != nil {
            showDataEntryOrDuplicateTransactionViewForTransaction()
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
        guard let nextTransaction = nextTransaction?.transaction, let autocompleteLedger = autocompleteLedger else {
            return nil
        }
        return autocompleteLedger.transactions.first {
            $0.postings.contains { $0.account.name == nextTransaction.postings.first?.account.name && $0.amount == nextTransaction.postings.first?.amount }
                && $0.metaData.date + Self.dateTolerance >= nextTransaction.metaData.date && $0.metaData.date - Self.dateTolerance <= nextTransaction.metaData.date
        }
    }

    private func useAccount(name: String) {
        do {
            switch importMode {
            case .csv:
                try fileImporter?.useAccount(name: name)
            case .text:
                try textImporter?.useAccount(name: name)
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
