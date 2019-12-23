//
//  RBCImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-08-28.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation

class RBCImporter: CSVImporter {

    private static let description1 = "Description 1"
    private static let description2 = "Description 2"
    private static let date = "Transaction Date"
    private static let amount = "CAD$"

    static let header = ["Account Type", "Account Number", date, "Cheque Number", description1, description2, amount, "USD$"]

    private static var dateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        return dateFormatter
    }()

    override func parseLine() -> CSVLine {
        let date = RBCImporter.dateFormatter.date(from: csvReader[RBCImporter.date]!)!
        let description = csvReader[RBCImporter.description1]! + " " + csvReader[RBCImporter.description2]!
        let amount = Decimal(string: csvReader[RBCImporter.amount]!, locale: Locale(identifier: "en_CA"))!
        let payee = description == "MONTHLY FEE " ? "RBC" : ""
        return CSVLine(date: date, description: description, amount: amount, payee: payee, price: nil)
    }

}
