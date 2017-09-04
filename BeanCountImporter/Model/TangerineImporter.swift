//
//  TangerineImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-08-28.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation

class TangerineImporter: CSVImporter {

    private static let date = "Date"
    private static let name = "Name"
    private static let memo = "Memo"
    private static let amount = "Amount"

    static let header = [date, "Transaction", name, memo, amount]

    private static var dateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        return dateFormatter
    }()

    override func parseLine() -> CSVLine {
        let date = TangerineImporter.dateFormatter.date(from: csvReader[TangerineImporter.date]!)!
        var description = ""
        var payee = ""
        if csvReader[TangerineImporter.name]! == "Interest Paid" {
            payee = "Tangerine"
        } else {
            description = csvReader[TangerineImporter.memo]!
        }
        let amount = Decimal(string: csvReader[TangerineImporter.amount]!, locale: Locale(identifier: "en_CA"))!
        return CSVLine(date: date, description: description, amount: amount, payee: payee)
    }

}
