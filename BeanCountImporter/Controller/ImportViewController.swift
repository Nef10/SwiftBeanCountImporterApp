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

    struct SegueIdentifier {
        static let dataEntrySheet = "dataEntrySheet"
    }

    var importMode: ImportMode?
    var autocompleteLedger: Ledger?

    private var resultLedger: Ledger = Ledger()
    private var nextTransactions: ImportedTransaction?

    @IBOutlet private var textView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard importMode != nil else {
            textView.string = "Unable to import data"
            return
        }
        updateOutput()
    }

    override func viewDidAppear() {
        showDataEntryViewForNextTransactionIfNeccessary()
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
            controller.importedTransaction = nextTransactions
            controller.delegate = self
            controller.ledger = autocompleteLedger
        default:
            break
        }
    }

    private func updateOutput() {
        textView.string = resultLedger.transactions.map { String(describing: $0) }.reduce("") { "\($0)\n\n\($1)" }.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func showDataEntryViewForNextTransactionIfNeccessary() {
        guard case let .csv(csvImporter)? = importMode else {
            return
        }
        nextTransactions = csvImporter?.parseLineIntoTransaction()
        if nextTransactions != nil {
            showDateEntryViewForNextTransaction()
        }
    }

    private func showDateEntryViewForNextTransaction() {
        performSegue(withIdentifier: NSStoryboardSegue.Identifier(SegueIdentifier.dataEntrySheet), sender: self)
    }

}

extension ImportViewController: DataEntryViewControllerDelegate {

    internal func finished(_ sheet: NSWindow, transaction: Transaction) {
        view.window?.endSheet(sheet)
        _ = resultLedger.add(transaction)
        updateOutput()
        showDataEntryViewForNextTransactionIfNeccessary()
    }

    func cancel(_ sheet: NSWindow) {
        view.window?.endSheet(sheet)
        view.window?.close()
    }

}
