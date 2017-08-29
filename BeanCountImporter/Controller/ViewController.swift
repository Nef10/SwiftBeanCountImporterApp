//
//  ViewController.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-08-28.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Cocoa
import CSV

class ViewController: NSViewController {

    @IBOutlet private weak var accountNameField: NSTextField!
    @IBOutlet private weak var commoditySymbolField: NSTextField!

    @IBAction private func importButtonClicked(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["csv"]
        openPanel.begin { [weak self] (response) in
            if response == .OK {
                self?.importFile(url: openPanel.url)
            }
        }
    }

    private func importFile(url: URL?) {
        guard let url = url, let importer = CSVImporter.new(url: url) else {
            let alert = NSAlert(error: NSError(domain: Bundle.main.bundleIdentifier ?? "",
                                               code: 1,
                                               userInfo: [NSLocalizedDescriptionKey: "Error while opening or parsing the selected file"]))
            alert.runModal()
            return
        }
        importer.parse(accountName: accountNameField.stringValue, commoditySymbol: commoditySymbolField.stringValue)
    }

}
