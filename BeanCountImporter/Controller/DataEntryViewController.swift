//
//  DataEntryViewController.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2018-02-02.
//  Copyright © 2018 Steffen Kötte. All rights reserved.
//

import Cocoa
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

    /// Will be called if the user cancels the data entry
    ///
    /// The delegate is responsible for dismissing the DataEntryViewController
    ///
    /// - Parameter sheet: window of the DataEntryViewController
    func cancel(_ sheet: NSWindow)
}

class DataEntryViewController: NSViewController {

    /// Leder used for autocomplete, can be nil
    var ledger: Ledger?

    /// Transaction to prepopulate the UI with, must not be nil upon loading the view
    var transaction: Transaction?

    /// Account of the posting which should not be shown, must not be nil upon loading the view
    var baseAccount: Account?

    /// Delegate which will be informed about continue and cancel actions
    weak var delegate: DataEntryViewControllerDelegate?

    private var relevantPosting: Posting?
    private var flag = Flag.incomplete
    private var accountComboBoxDataSource: AccountComboBoxDataSource?
    private var payeeComboBoxDataSource: PayeeComboBoxDataSource?

    @IBOutlet private weak var dateField: NSTextField!
    @IBOutlet private weak var amountField: NSTextField!
    @IBOutlet private weak var descriptionField: NSTextField!
    @IBOutlet private weak var payeeField: NSComboBox!
    @IBOutlet private weak var saveDescriptionPayeeCheckbox: NSButton!
    @IBOutlet private weak var tagField: NSTokenField!
    @IBOutlet private weak var accountField: NSComboBox!
    @IBOutlet private weak var saveAccountCheckbox: NSButton!
    @IBOutlet private weak var incompleteFlagButton: NSButton!
    @IBOutlet private weak var completeFlagButton: NSButton!

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
        delegate?.finished(view.window!, transaction: transaction)
    }

    @IBAction private func cancelButtonPressed(_ sender: Any) {
        self.delegate?.cancel(view.window!)
    }

    @IBAction func flagRadioButtonChanged(_ sender: NSButton) {
        if completeFlagButton.state == .on {
            flag = .complete
        } else {
            flag = .incomplete
        }
    }

    private func setupUI() {
        tagField.tokenizingCharacterSet = CharacterSet.whitespacesAndNewlines
        if let ledger = ledger {
            accountComboBoxDataSource = AccountComboBoxDataSource(ledger: ledger)
            accountField.dataSource = accountComboBoxDataSource
            payeeComboBoxDataSource = PayeeComboBoxDataSource(ledger: ledger)
            payeeField.dataSource = payeeComboBoxDataSource
        }
    }

    private func processPassedData() {
        relevantPosting = transaction?.postings.first { $0.account != baseAccount }
    }

    private func isPassedDataValid() -> Bool {
        return transaction != nil && relevantPosting != nil && baseAccount != nil
    }

    private func handleInvalidPassedData() {
        assertionFailure("Passed invalid data to DataEntryViewController")
        self.delegate?.cancel(view.window!)
    }

    private func prepopulateUI() {
        let metaData = transaction!.metaData
        let posting = relevantPosting!

        dateField.stringValue = DataEntryViewController.dateFormatter.string(from: metaData.date)
        amountField.stringValue = String(describing: posting.amount) + (posting.price != nil ? " @ \(String(describing: posting.price!))" : "")
        descriptionField.stringValue = metaData.narration
        payeeField.stringValue = metaData.payee
        if metaData.flag == .complete {
            completeFlagButton.state = .on
        } else {
            incompleteFlagButton.state = .on
        }
        accountField.stringValue = posting.account.name
    }

    private func getUpdatedTransaction() throws -> Transaction {
        let metaData = TransactionMetaData(date: transaction!.metaData.date,
                                           payee: payeeField.stringValue,
                                           narration: descriptionField.stringValue,
                                           flag: flag,
                                           tags: getTags())
        let posting = Posting(account: try Account(name: accountField.stringValue),
                              amount: relevantPosting!.amount,
                              transaction: transaction!,
                              price: relevantPosting?.price)
        var postings = transaction!.postings.filter { $0 != relevantPosting }
        postings.append(posting)
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

    static private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

}
