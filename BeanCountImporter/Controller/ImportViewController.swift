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
    }

    private static let dateTolerance: TimeInterval = 2 * 60 * 60 * 24 // 2 days +- to check for duplicate transaction

    var importMode: ImportMode?
    var autocompleteLedgerURL: URL?

    private var autocompleteLedger: Ledger?
    private var resultLedger: Ledger = Ledger()
    private var nextTransaction: ImportedTransaction?
    private var csvImporter: CSVImporter?
    private var manuLifeImporter: ManuLifeImporter?

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
            self?.importData()
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case SegueIdentifier.dataEntrySheet:
            guard let controller = segue.destinationController as? DataEntryViewController, case .csv = importMode else {
                return
            }
            controller.baseAccount = csvImporter?.account
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
        case let .csv(fileURL, account, commodity)?:
            csvImporter = CSVImporter.new(url: fileURL, accountName: account, commoditySymbol: commodity)
            csvImporter?.loadFile()
        case let .text(_, _, account, commodity)?:
            manuLifeImporter = ManuLifeImporter(autocompleteLedger: autocompleteLedger, accountName: account, commodityString: commodity)
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
        csvImporter != nil || manuLifeImporter != nil
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

    private func importData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            if let manuLifeImporter = self.manuLifeImporter, case let .text(transactionString, balanceString, _, _)? = self.importMode {
                self.textView.string = manuLifeImporter.parse(transaction: transactionString, balance: balanceString)
            } else {
                self.showDataEntryViewForNextTransactionIfNeccessary()
            }
        }
    }

    private func showDataEntryViewForNextTransactionIfNeccessary() {
        guard case .csv = importMode else {
            return
        }
        nextTransaction = csvImporter?.parseLineIntoTransaction()
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

}

extension ImportViewController: DataEntryViewControllerDelegate, DuplicateTransactionViewControllerDelegate {

    func finished(_ sheet: NSWindow, transaction: Transaction) {
        view.window?.endSheet(sheet)
        _ = resultLedger.add(transaction)
        updateOutput()
        showDataEntryViewForNextTransactionIfNeccessary()
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
