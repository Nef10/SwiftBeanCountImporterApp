//
//  LoadingIndicatorViewController.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2019-12-23.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation

class LoadingIndicatorViewController: NSViewController {

    private var textCache = "Loading"

    @IBOutlet private var progressIndicator: NSProgressIndicator!
    @IBOutlet private var textField: NSTextField!

    override func viewWillAppear() {
        progressIndicator.startAnimation(nil)
        textField.stringValue = textCache // in case updateText was called beforet the view was loaded
        super.viewWillAppear()
    }

    func updateText(text: String) {
        textCache = text
        if isViewLoaded {
            textField.stringValue = text
        }
    }

}
