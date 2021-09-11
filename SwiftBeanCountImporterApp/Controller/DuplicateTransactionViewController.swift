//
//  DuplicateTransactionViewController.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2019-12-23.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

import Cocoa
import SwiftBeanCountModel

protocol DuplicateTransactionViewControllerDelegate: AnyObject {

    /// Will be called if the user clicked skip
    ///
    /// The delegate is responsible for dismissing the DataEntryViewController
    ///
    /// - Parameter sheet: window of the DataEntryViewController
    func skipImporting(_ sheet: NSWindow)

    /// Will be called if the user clicked import anyway
    ///
    /// The delegate is responsible for dismissing the DataEntryViewController
    ///
    /// - Parameter sheet: window of the DataEntryViewController
    func importAnyway(_ sheet: NSWindow)

    /// Will be called if the user cancels the dialog
    ///
    /// The delegate is responsible for dismissing the DataEntryViewController
    ///
    /// - Parameter sheet: window of the DataEntryViewController
    func cancel(_ sheet: NSWindow)
}

class DuplicateTransactionViewController: NSViewController {

    /// Transaction which could be imported, must not be nil upon loading the view
    var importedTransaction: Transaction?

    /// Transaction which already exists in the ledger, must not be nil upon loading the view
    var existingTransaction: Transaction?

    /// Name of the import where the duplicate transaction was found
    var importName: String?

    /// Delegate which will be informed about continue and cancel actions
    weak var delegate: DuplicateTransactionViewControllerDelegate?

    @IBOutlet private var textField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard isPassedDataValid() else {
            handleInvalidPassedData()
            return
        }
        populateUI()
    }

    @IBAction private func skipButtonPressed(_ sender: Any) {
        self.delegate?.skipImporting(view.window!)
    }

    @IBAction private func importAnywayButtonPressed(_ sender: Any) {
        self.delegate?.importAnyway(view.window!)
    }

    @IBAction private func cancelButtonPressed(_ sender: Any) {
        self.delegate?.cancel(view.window!)
    }

    private func isPassedDataValid() -> Bool {
        importedTransaction != nil && existingTransaction != nil && importName != nil
    }

    private func handleInvalidPassedData() {
        assertionFailure("Passed invalid data to DuplicateTransactionViewController")
        self.delegate?.importAnyway(view.window!)
    }

    private func populateUI() {
        textField.stringValue = """
            The transaction found in the import data of \(importName!):

            \(String(describing: importedTransaction!))

            seems to be alredy present in your ledger:

            \(String(describing: existingTransaction!))

            How do you want to proceed?
            """
    }

}
