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

    var csvImporter: CSVImporter?

    private var ledger: Ledger = Ledger()
    private var transactions = [Transaction]()
    private var transactionsFinished = 0

    @IBOutlet private var textView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let importer = csvImporter else {
            textView.string = "Unable to import file"
            return
        }
        transactions = importer.parse()
        updateOutput()
    }

    override func viewDidAppear() {
        showDataEntryViewForNextTransactionIfNeccessary()
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier.rawValue {
        case SegueIdentifier.dataEntrySheet:
            guard let controller = segue.destinationController as? DataEntryViewController else {
                return
            }
            controller.baseAccount = csvImporter?.account
            controller.transaction = transactions[transactionsFinished]
            controller.delegate = self
        default:
            break
        }
    }

    private func updateOutput() {
        textView.string = String(describing: ledger).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func showDataEntryViewForNextTransactionIfNeccessary() {
        if transactionsFinished < transactions.count {
            showDateEntryViewForNextTransaction()
        }
    }

    private func showDateEntryViewForNextTransaction() {
        performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: SegueIdentifier.dataEntrySheet), sender: self)
    }

}

extension ImportViewController: DataEntryViewControllerDelegate {

    internal func finished(_ sheet: NSWindow, transaction: Transaction) {
        view.window?.endSheet(sheet)
        _ = ledger.add(transaction)
        updateOutput()
        transactionsFinished += 1
        showDataEntryViewForNextTransactionIfNeccessary()
    }

    func cancel(_ sheet: NSWindow) {
        view.window?.endSheet(sheet)
        view.window?.close()
    }

}
