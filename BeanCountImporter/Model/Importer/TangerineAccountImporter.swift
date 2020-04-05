//
//  TangerineAccountImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-08-28.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation

class TangerineAccountImporter: CSVImporter {

    private static let date = "Date"
    private static let name = "Name"
    private static let memo = "Memo"
    private static let amount = "Amount"

    static let header = [date, "Transaction", name, memo, amount]

    static let interac = "INTERAC e-Transfer From: "
    static let interest = "Interest Paid"

    private static var dateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        return dateFormatter
    }()

    override func parseLine() -> CSVLine {
        let date = Self.dateFormatter.date(from: csvReader[Self.date]!)!
        var description = ""
        var payee = ""
        if csvReader[Self.name]! == Self.interest {
            payee = "Tangerine"
        } else {
            description = csvReader[Self.memo]!
            if csvReader[Self.name]!.starts(with: Self.interac) {
                description = "\(csvReader[Self.name]!.replacingOccurrences(of: Self.interac, with: "")) - \(description)"
            }
        }
        let amount = Decimal(string: csvReader[Self.amount]!, locale: Locale(identifier: "en_CA"))!
        return CSVLine(date: date, description: description, amount: amount, payee: payee, price: nil)
    }

}
