//
//  ImportViewController.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-09-03.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Cocoa

class ImportViewController: NSViewController {

    var csvImporter: CSVImporter?

    @IBOutlet private var textView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let importer = csvImporter else {
            textView.string = "Unable to import file"
            return
        }
        textView.string = String(describing: importer.parse())
    }

}
