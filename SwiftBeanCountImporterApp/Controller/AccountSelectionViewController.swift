//
//  AccountSelectionViewController.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-14.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation

protocol AccountSelectionViewControllerDelegate: AnyObject {

    func finished(_ sheet: NSWindow, accountName: String)
    func cancel(_ sheet: NSWindow)

}

class AccountSelectionViewController: NSViewController {

    /// Accounts which the importer thinks the file belongs to, can be empty
    var possibleAccounts = [String]()

    /// Filename of the imported file, nil if imported from text
    var fileName: String?

    /// Delegate to send finish and cancel message to
    weak var delegate: AccountSelectionViewControllerDelegate?

    @IBOutlet private var comboBox: NSComboBox!
    @IBOutlet private var label: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let fileName = fileName {
            label.stringValue = "Please select the account for file \(fileName):"
        } else {
            label.stringValue = "Please select the account for the entered text:"
        }
        comboBox.removeAllItems()
        comboBox.addItems(withObjectValues: possibleAccounts)
    }

    @IBAction private func okButtonPressed(_ sender: NSButton) {
        let account = comboBox.stringValue
        delegate?.finished(view.window!, accountName: account)
    }

    @IBAction private func cancelButtonPressed(_ sender: NSButton) {
        delegate?.cancel(view.window!)
    }

}
