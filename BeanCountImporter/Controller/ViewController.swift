//
//  ViewController.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-08-28.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Cocoa
import CSV

class SelectorViewController: NSViewController {

    @IBOutlet private weak var accountNameField: NSTextField!
    @IBOutlet private weak var commoditySymbolField: NSTextField!
    @IBOutlet private weak var fileNameLabel: NSTextField!

    private var fileURL: URL?

    @IBAction private func selectButtonClicked(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["csv"]
        openPanel.begin { [weak self] (response) in
            if response == .OK {
                self?.fileURL = openPanel.url
                self?.fileNameLabel.stringValue = self?.fileURL?.lastPathComponent ?? ""
            }
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier.rawValue {
        case "showImportSheet":
            guard let controller = segue.destinationController as? ImportViewController else {
                return
            }
            controller.csvImporter = CSVImporter.new(url: fileURL, accountName: accountNameField.stringValue, commoditySymbol: commoditySymbolField.stringValue)
        default:
            break
        }
    }

}
