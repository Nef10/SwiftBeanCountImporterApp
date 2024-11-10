//
//  ImporterInputSuggestionViewController.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-14.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation
import SwiftBeanCountImporter

protocol ImporterInputViewControllerDelegate: AnyObject {

    func finished(_ sheet: NSWindow, input: String)
    func cancel(_ sheet: NSWindow)

}

class ImporterInputViewController: NSViewController {

    /// Name describing the import, to tell the user for which import info is requested
    var importName: String?

    /// Name describing the input
    var name: String?

    /// Type of the input
    var type: ImporterInputRequestType!

    /// Delegate to send finish and cancel message to
    weak var delegate: ImporterInputViewControllerDelegate?

    @IBOutlet private var comboBox: NSComboBox!
    @IBOutlet private var label: NSTextField!
    @IBOutlet private var textField: NSTextField!
    @IBOutlet private var secureTextField: NSSecureTextField!
    @IBOutlet private var cancelButton: NSButton!
    @IBOutlet private var okButton: NSButton!

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let importName, let name else {
            fatalError("importName and name are required to create an AccountSelectionViewController")
        }
        let verb = if case .choice = type { "select" } else { "enter" }
        label.stringValue = "\(type == .bool ? "" : "Please \(verb) ")\(name) for the following import: \(importName)"
        switch type {
        case .text(let suggestions):
            secureTextField.isHidden = true
            okButton.title = "Ok"
            cancelButton.title = "Cancel"
            if suggestions.isEmpty {
                comboBox.isHidden = true
                textField.contentType = nil
                textField.isHidden = false
            } else {
                comboBox.isHidden = false
                textField.isHidden = true
                comboBox.removeAllItems()
                comboBox.addItems(withObjectValues: suggestions)
                comboBox.isEditable = true
            }
        case .secret:
            comboBox.isHidden = true
            textField.isHidden = true
            secureTextField.isHidden = false
            okButton.title = "Ok"
            cancelButton.title = "Cancel"
        case .otp:
            comboBox.isHidden = true
            textField.contentType = .oneTimeCode
            textField.isHidden = false
            secureTextField.isHidden = true
            okButton.title = "Ok"
            cancelButton.title = "Cancel"
        case .bool:
            comboBox.isHidden = true
            textField.isHidden = true
            secureTextField.isHidden = true
            okButton.title = "Yes"
            cancelButton.title = "No"
        case .choice(let options):
            secureTextField.isHidden = true
            okButton.title = "Ok"
            cancelButton.title = "Cancel"
            comboBox.isHidden = false
            textField.isHidden = true
            comboBox.removeAllItems()
            comboBox.addItems(withObjectValues: options)
            comboBox.isEditable = false
        case .none:
            fatalError("No type configured in ImporterInputViewController")
        }
    }

    @IBAction private func okButtonPressed(_: NSButton) {
        let input: String
        switch type {
        case .text(let suggestions):
                if suggestions.isEmpty {
                input = textField.stringValue
            } else {
                input = comboBox.stringValue
            }
        case .secret:
            input = secureTextField.stringValue
        case .otp:
            input = textField.stringValue
        case .bool:
            input = "true"
        case .choice:
            input = comboBox.stringValue
        case .none:
            fatalError("No type configured in ImporterInputViewController")
        }
        delegate?.finished(view.window!, input: input)
    }

    @IBAction private func cancelButtonPressed(_: NSButton) {
        if case .bool = type {
            delegate?.finished(view.window!, input: "false")
        } else {
            delegate?.cancel(view.window!)
        }
    }

}
