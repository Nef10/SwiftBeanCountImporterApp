//
//  TextEntryViewController.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2019-09-07.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation

protocol TextEntryViewControllerDelegate: AnyObject {

    /// Will be called after the user clicked Finish
    ///
    /// The delegate is responsible for dismissing the TextEntryViewController
    ///
    /// - Parameters:
    ///   - sheet: window of the TextEntryViewController
    ///   - transaction: text in the transaction field
    ///   - balance: text in the transaction field
    func finished(_ sheet: NSWindow, transaction: String, balance: String)

    /// Will be called if the user cancels the data entry
    ///
    /// The delegate is responsible for dismissing the TextEntryViewController
    ///
    /// - Parameter sheet: window of the TextEntryViewController
    func cancel(_ sheet: NSWindow)
}

class TextEntryViewController: NSViewController {

    /// Delegate which will be informed about continue and cancel actions
    weak var delegate: TextEntryViewControllerDelegate?

    @IBOutlet private var transactionTextView: NSTextView!
    @IBOutlet private var balanceTextView: NSTextView!

    @IBAction private func cancelButtonPressed(_: Any) {
        delegate?.cancel(view.window!)
    }

    @IBAction private func continueButtonPressed(_: Any) {
        delegate?.finished(view.window!, transaction: transactionTextView.textStorage?.string ?? "", balance: balanceTextView.textStorage?.string ?? "")
    }

}
