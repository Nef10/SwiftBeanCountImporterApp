//
//  DataEntryViewController.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2018-02-02.
//  Copyright © 2018 Steffen Kötte. All rights reserved.
//

import Cocoa
import SwiftBeanCountImporter
import SwiftBeanCountModel

protocol DataEntryViewControllerDelegate: AnyObject {

    /// Will be called after the user clicked continue and the data validation passed
    ///
    /// The delegate is responsible for dismissing the DataEntryViewController
    ///
    /// - Parameters:
    ///   - sheet: window of the DataEntryViewController
    ///   - transaction: updated transaction
    func finished(_ sheet: NSWindow, transaction: Transaction)

    /// Will be called if the user clicked skip
    ///
    /// The delegate is responsible for dismissing the DataEntryViewController
    ///
    /// - Parameter sheet: window of the DataEntryViewController
    func skipImporting(_ sheet: NSWindow)

    /// Will be called if the user cancels the data entry
    ///
    /// The delegate is responsible for dismissing the DataEntryViewController
    ///
    /// - Parameter sheet: window of the DataEntryViewController
    func cancel(_ sheet: NSWindow)
}

class DataEntryViewController: NSViewController {

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    /// Leder used for autocomplete, can be nil
    var ledger: Ledger?

    /// Transaction to prepopulate the UI with, must not be nil upon loading the view
    var importedTransaction: ImportedTransaction?

    /// Delegate which will be informed about continue and cancel actions
    weak var delegate: DataEntryViewControllerDelegate?

    private var relevantPosting: Posting?
    private var flag = Flag.incomplete
    private var accountComboBoxDataSource: AccountComboBoxDataSource?
    private var payeeComboBoxDataSource: PayeeComboBoxDataSource?
    private var tagTokenFieldDataSource: TagTokenFieldDataSource?
    private var transaction: Transaction?

    @IBOutlet private var dateField: NSTextField!
    @IBOutlet private var amountField: NSTextField!
    @IBOutlet private var descriptionField: NSTextField!
    @IBOutlet private var payeeField: NSComboBox!
    @IBOutlet private var saveDescriptionPayeeCheckbox: NSButton!
    @IBOutlet private var tagField: NSTokenField!
    @IBOutlet private var accountField: NSComboBox!
    @IBOutlet private var saveAccountCheckbox: NSButton!
    @IBOutlet private var incompleteFlagButton: NSButton!
    @IBOutlet private var completeFlagButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        processPassedData()
        guard isPassedDataValid() else {
            handleInvalidPassedData()
            return
        }
        setupUI()
        prepopulateUI()
    }

    @IBAction private func continueButtonPressed(_ sender: Any) {
        guard let transaction = try? getUpdatedTransaction() else {
            showAccountValidationError()
            return
        }
        savePrefrillData(transaction: transaction)
        delegate?.finished(view.window!, transaction: transaction)
    }

    @IBAction private func cancelButtonPressed(_ sender: Any) {
        self.delegate?.cancel(view.window!)
    }

    @IBAction private func skipButtonPressed(_ sender: Any) {
        self.delegate?.skipImporting(view.window!)
    }

    @IBAction private func saveDescriptionPayeeCheckboxClicked(_ sender: Any) {
        saveAccountCheckbox.isEnabled = saveDescriptionPayeeCheckbox.state == .on
    }

    @IBAction private func flagRadioButtonChanged(_ sender: NSButton) {
        if completeFlagButton.state == .on {
            flag = .complete
        } else {
            flag = .incomplete
        }
    }

    private func setupUI() {
        tagField.tokenizingCharacterSet = CharacterSet.whitespacesAndNewlines
        if let ledger {
            accountComboBoxDataSource = AccountComboBoxDataSource(ledger: ledger)
            accountField.dataSource = accountComboBoxDataSource
            payeeComboBoxDataSource = PayeeComboBoxDataSource(ledger: ledger)
            payeeField.dataSource = payeeComboBoxDataSource
            tagTokenFieldDataSource = TagTokenFieldDataSource(ledger: ledger)
            tagField.delegate = tagTokenFieldDataSource
        }
    }

    private func processPassedData() {
        transaction = importedTransaction?.transaction
        relevantPosting = transaction?.postings.first { $0.accountName != importedTransaction?.accountName }
    }

    private func isPassedDataValid() -> Bool {
        transaction != nil && relevantPosting != nil
    }

    private func handleInvalidPassedData() {
        assertionFailure("Passed invalid data to DataEntryViewController")
        self.delegate?.cancel(view.window!)
    }

    private func prepopulateUI() {
        let metaData = transaction!.metaData
        let posting = relevantPosting!

        dateField.stringValue = Self.dateFormatter.string(from: metaData.date)
        amountField.stringValue = String(describing: posting.amount) + (posting.price != nil ? " @ \(String(describing: posting.price!))" : "")
        descriptionField.stringValue = metaData.narration
        payeeField.stringValue = metaData.payee
        if metaData.flag == .complete {
            completeFlagButton.state = .on
            flag = .complete
        } else {
            incompleteFlagButton.state = .on
            flag = .incomplete
        }
        accountField.stringValue = posting.accountName.fullName
    }

    private func getUpdatedTransaction() throws -> Transaction {
        let metaData = TransactionMetaData(date: transaction!.metaData.date,
                                           payee: payeeField.stringValue,
                                           narration: descriptionField.stringValue,
                                           flag: flag,
                                           tags: getTags(),
                                           metaData: transaction!.metaData.metaData)
        let relevantPosting = Posting(accountName: try AccountName(accountField.stringValue),
                                      amount: self.relevantPosting!.amount,
                                      price: self.relevantPosting?.price)
        var postings: [Posting] = transaction!.postings.filter { $0 != self.relevantPosting }
        postings.append(relevantPosting)
        self.relevantPosting = relevantPosting
        return Transaction(metaData: metaData, postings: postings)
    }

    private func getTags() -> [Tag] {
        let tagStrings = Set(tagField.stringValue.components(separatedBy: CharacterSet.whitespacesAndNewlines))
        var tags = [Tag]()
        for tagString in tagStrings {
            guard !tagString.isEmpty else {
                continue
            }
            var tag = tagString
            if tagString.starts(with: "#") {
                tag = String(tagString.dropFirst())
            }
            tags.append(Tag(name: tag))
        }
        return tags
    }

    private func showAccountValidationError() {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.messageText = "Please enter a valid account."
        alert.beginSheetModal(for: view.window!, completionHandler: nil)
    }

    private func savePrefrillData(transaction: Transaction) {
        if saveDescriptionPayeeCheckbox.state == .on, let importedTransaction {
            importedTransaction.saveMapped(description: transaction.metaData.narration,
                                           payee: transaction.metaData.payee,
                                           accountName: saveAccountCheckbox.state == .on ? relevantPosting?.accountName : nil)
        }
    }

}
