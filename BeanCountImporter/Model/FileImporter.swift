//
//  FileImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-08-28.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import CSV
import Foundation
import SwiftBeanCountModel

enum FileImporterManager {

    static func new(url: URL?, accountName: String, commoditySymbol: String) -> FileImporter? {
        CSVImporterManager.new(url: url, accountName: accountName, commoditySymbol: commoditySymbol)
    }

}

struct ImportedTransaction {

    let transaction: Transaction
    let originalDescription: String

}

protocol FileImporter {

    var account: Account { get }

    func loadFile()
    func parseLineIntoTransaction() -> ImportedTransaction?

}
