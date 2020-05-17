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

    static func new(ledger: Ledger?, transaction: String, balance: String) -> TextImporter? {
        ManuLifeImporter(ledger: ledger, transaction: transaction, balance: balance)
    }

}

protocol TextImporter: Importer {

    init(ledger: Ledger?, transaction: String, balance: String)

    func parse() -> String

}
