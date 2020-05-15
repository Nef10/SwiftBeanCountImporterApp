//
//  TextImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-10.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Foundation
import SwiftBeanCountModel

enum TextImporterManager {

    static var importers: [TextImporter.Type] {
        [ManuLifeImporter.self]
    }

    static func new(autocompleteLedger: Ledger?) -> TextImporter? {
        ManuLifeImporter(autocompleteLedger: autocompleteLedger)
    }

}

protocol TextImporter: Importer {

    init(autocompleteLedger: Ledger?)

    func parse(transaction: String, balance: String) -> String

}
