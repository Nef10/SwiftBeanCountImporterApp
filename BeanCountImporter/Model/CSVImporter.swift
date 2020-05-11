//
//  CSVImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-10.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import CSV
import Foundation
import SwiftBeanCountModel

struct CSVLine {
    let date: Date
    let description: String
    let amount: Decimal
    let payee: String
    let price: Amount?
}

enum CSVImporterManager {

    static var importers: [CSVImporter.Type] {
        [
            RBCImporter.self,
            TangerineCardImporter.self,
            TangerineAccountImporter.self,
            LunchOnUsImporter.self,
            N26Importer.self,
            RogersImporter.self,
            SimpliiImporter.self
        ]
    }

    static func new(url: URL?, accountName: String, commoditySymbol: String) -> FileImporter? {
        guard let url = url, let csvReader = openFile(url), let headerRow = csvReader.headerRow, let account = try? Account(name: accountName) else {
            return nil
        }
        let importer = Self.importers.first {
            $0.header == headerRow
        }
        guard let importerClass = importer else {
            return nil
        }
        return importerClass.init(csvReader: csvReader, account: account, commoditySymbol: commoditySymbol)
    }

    private static func openFile(_ url: URL) -> CSVReader? {
        let inputStream = InputStream(url: url)
        guard let input = inputStream else {
            return nil
        }
        do {
            return try CSVReader(stream: input, hasHeaderRow: true, trimFields: true)
        } catch {
            return nil
        }
    }

}

protocol CSVImporter: FileImporter {

    static var header: [String] { get }

    init(csvReader: CSVReader, account: Account, commoditySymbol: String)

}
