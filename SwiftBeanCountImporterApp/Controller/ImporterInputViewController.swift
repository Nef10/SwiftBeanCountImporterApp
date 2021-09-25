//
//  ImporterInputSuggestionViewController.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-14.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation

protocol ImporterInputViewControllerDelegate: AnyObject {

    func finished(_ sheet: NSWindow, input: String)
    func cancel(_ sheet: NSWindow)

}

class ImporterInputViewController: NSViewController {

    /// Suggestions which should be provided to the user
    var suggestions = [String]()

    /// Name describing the import, to tell the user for which import info is requested
    var importName: String?

    /// Name describing the input
    var name: String?

    /// Should the input be in a secure text field
    var isSecure = false

    /// Delegate to send finish and cancel message to
    weak var delegate: ImporterInputViewControllerDelegate?

    @IBOutlet private var comboBox: NSComboBox!
    @IBOutlet private var label: NSTextField!
    @IBOutlet private var textField: NSTextField!
    @IBOutlet private var secureTextField: NSSecureTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let importName = importName, let name = name else {
            fatalError("importName and name are required to create an AccountSelectionViewController")
        }
        label.stringValue = "Please enter \(name) for the following import: \(importName)"
        if isSecure {
            comboBox.isHidden = true
            textField.isHidden = true
            secureTextField.isHidden = false
        } else if !suggestions.isEmpty {
            comboBox.isHidden = false
            textField.isHidden = true
            secureTextField.isHidden = true
            comboBox.removeAllItems()
            comboBox.addItems(withObjectValues: suggestions)
        } else {
            comboBox.isHidden = true
            textField.isHidden = false
            secureTextField.isHidden = true
        }
    }

    @IBAction private func okButtonPressed(_ sender: NSButton) {
        let input: String
        if isSecure {
            input = secureTextField.stringValue
        } else if !suggestions.isEmpty {
            input = comboBox.stringValue
        } else {
            input = textField.stringValue
        }
        delegate?.finished(view.window!, input: input)
    }

    @IBAction private func cancelButtonPressed(_ sender: NSButton) {
        delegate?.cancel(view.window!)
    }

}
