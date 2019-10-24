//
//  N26Importer.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2019-10-23.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

import Foundation

class N26Importer: CSVImporter {

    private static let description = "Verwendungszweck"
    private static let amount = "Betrag (EUR)"
    private static let amountForeignCurrency = "Betrag (Fremdwährung)"
    private static let foreignCurrency = "Fremdwährung"
    private static let exchangeRate = "Wechselkurs"
    private static let date = "Datum"
    private static let recipient = "Empfänger"

    static let header = [date, recipient, "Kontonummer", "Transaktionstyp", description, "Kategorie", amount, amountForeignCurrency, foreignCurrency, exchangeRate]

    private static var dateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    override func parseLine() -> CSVLine {
        let date = Self.dateFormatter.date(from: csvReader[Self.date]!)!
        let recipient = csvReader[Self.recipient] ?? ""
        let description = csvReader[Self.description] ?? ""
        let amount = Decimal(string: csvReader[Self.amount]!, locale: Locale(identifier: "en_CA"))!
        return CSVLine(date: date, description: description, amount: amount, payee: recipient)
    }

}
