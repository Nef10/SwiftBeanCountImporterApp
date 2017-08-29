//
//  CSVImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-08-28.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import CSV
import Foundation

class CSVImporter {

    private static let headerRBC = ["Account Type", "Account Number", "Transaction Date", "Cheque Number", "Description 1", "Description 2", "CAD$", "USD$"]
    private static let headerTangerine = ["Date", "Transaction", "Name", "Memo", "Amount"]

    internal let payees = [
        "Safeway",
        "Jugo Juice",
        "Starbucks",
        "Ebiten",
        "Mcdonald's",
        "Tim Horton's",
        "Mastercuts",
        "Fresh Bowl",
        ]

    internal let naming = [
        "Bean Around The": "Bean around the World",
        "Compass Vending": "Translink",
        "Ikea Richmond": "IKEA",
        "Tacofino Yaleto": "Tacofino",
        "Grounds For App": "Grounds For Appeal",
        "The Greek By An": "The Greek",
        "Phat Sports Bar": "PHAT Sports Bar",
        "A&w": "A&W",
        ]

    internal let accounts = [
        "Safeway": "Expenses:Food:Groceries",
        "Jugo Juice": "Expenses:Food:Snack",
        "Starbucks": "Expenses:Food:Snack",
        "Ebiten": "Expenses:Food:TakeOut",
        "Mcdonald's": "Expenses:Food:FastFood",
        "Tim Horton's": "Expenses:Food:Snack",
        "Mastercuts": "Expenses:Living:Services",
        "Fresh Bowl": "Expenses:Food:TakeOut",
        "Bean around the World": "Expenses:Food:TakeOut",
        "Tacofino": "Expenses:Food:TakeOut",
        "Grounds For Appeal": "Expenses:Food:TakeOut",
        "PHAT Sports Bar": "Expenses:Food:TakeOut",
        "A&W": "Expenses:Food:FastFood",
        ]

    private enum CSVType {
        case RBC, tangerine, unknown
    }

    let csvReader: CSVReader

    internal init(csvReader: CSVReader) {
        self.csvReader = csvReader
    }

    func parse(accountName: String, commoditySymbol: String) {
        fatalError("Must Override")
    }

    static func new(url: URL) -> CSVImporter? {
        guard let csvReader = openFile(url) else {
            return nil
        }
        let csvType = getCSVType(csvReader)
        switch csvType {
        case .RBC:
            return RBCImporter(csvReader: csvReader)
        case .tangerine:
            return TangerineImporter(csvReader: csvReader)
        default:
            return nil
        }
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

    private static func getCSVType(_ csv: CSVReader) -> CSVType {
        guard let headerRow = csv.headerRow else {
            return .unknown
        }
        if headerRow == headerRBC {
            return .RBC
        } else if headerRow == headerTangerine {
            return .tangerine
        } else {
            return .unknown
        }
    }

}
