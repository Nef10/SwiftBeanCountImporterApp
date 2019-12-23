//
//  ImportViewController.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-09-03.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Cocoa
import SwiftBeanCountModel

class ImportViewController: NSViewController {

    enum SegueIdentifier {
        static let dataEntrySheet = "dataEntrySheet"
        static let duplicateTransactionSheet = "duplicateTransactionSheet"
    }

    var importMode: ImportMode?
    var autocompleteLedger: Ledger?

    private var resultLedger: Ledger = Ledger()
    private var nextTransaction: ImportedTransaction?

    @IBOutlet private var textView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let font = NSFont(name: "Menlo", size: 12) {
            textView.typingAttributes = [NSAttributedString.Key.font: font]
        }
    }

    override func viewDidAppear() {
        importData()
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case SegueIdentifier.dataEntrySheet:
            guard let controller = segue.destinationController as? DataEntryViewController, case let .csv(csvImporter)? = importMode else {
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
        default:
            break
        }
    }

    private func updateOutput() {
        textView.string = resultLedger.transactions.map { String(describing: $0) }.reduce(into: "") { $0.append("\n\n\($1)") }.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func importData() {
        switch importMode {
        case .csv?:
            showDataEntryViewForNextTransactionIfNeccessary()
        case let .text(transactionString, balanceString, account, commodity)?:
            let importer = ManuLifeImporter(autocompleteLedger: autocompleteLedger, accountName: account, commodityString: commodity)
            textView.string = importer.parse(transaction: transactionString, balance: balanceString)
        case .none:
            textView.string = "Unable to import data"
        }
    }

    private func showDataEntryViewForNextTransactionIfNeccessary() {
        guard case let .csv(csvImporter)? = importMode else {
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
                && $0.metaData.date == nextTransaction.metaData.date
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
