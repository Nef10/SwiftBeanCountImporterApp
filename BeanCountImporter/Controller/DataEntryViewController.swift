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
    func finished(_ sheet: NSWindow, transaction: Transaction)
    func cancel(_ sheet: NSWindow)
}

class DataEntryViewController: NSViewController {

    var transaction: Transaction?
    var baseAccount: Account?
    weak var delegate: DataEntryViewControllerDelegate?

    private var relevantPosting: Posting?
    private var flag = Flag.incomplete

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
        prepopulateUI()
        tagField.tokenizingCharacterSet = CharacterSet.whitespacesAndNewlines
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
            tags.append(Tag(name: tagString))
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
        let _dateFormatter = DateFormatter()
        _dateFormatter.dateFormat = "yyyy-MM-dd"
        return _dateFormatter
    }()

}
