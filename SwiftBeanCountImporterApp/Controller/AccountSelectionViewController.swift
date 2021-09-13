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

    /// Name describing the import, to tell the user for which file / download info is requested
    var importName: String?

    /// Delegate to send finish and cancel message to
    weak var delegate: AccountSelectionViewControllerDelegate?

    @IBOutlet private var comboBox: NSComboBox!
    @IBOutlet private var label: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let importName = importName else {
            fatalError("importName is required to create an AccountSelectionViewController")
        }
        label.stringValue = "Please select the account for the following import: \(importName)"
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
