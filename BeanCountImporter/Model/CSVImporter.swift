//
//  CSVImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2017-08-28.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import CSV
import Foundation
import SwiftBeanCountModel

class CSVImporter {

    struct CSVLine {
        let date: Date
        let description: String
        let amount: Decimal
        let payee: String
        let price: Amount?
    }

    static let userDefaultsPayees = "payees"
    static let userDefaultsAccounts = "accounts"
    static let userDefaultsDescription = "description"

    private static let regexe: [NSRegularExpression] = {  // swiftlint:disable force_try
        [
            try! NSRegularExpression(pattern: "(C-)?IDP PURCHASE( )?-( )?[0-9]{4}", options: []),
            try! NSRegularExpression(pattern: "VISA DEBIT (PUR|REF)-[0-9]{4}", options: []),
            try! NSRegularExpression(pattern: "WWWINTERAC PUR [0-9]{4}", options: []),
            try! NSRegularExpression(pattern: "INTERAC E-TRF- [0-9]{4}", options: []),
            try! NSRegularExpression(pattern: "[0-9]* ~ Internet Withdrawal", options: []),
            try! NSRegularExpression(pattern: "(-)? SAP(?! CANADA)", options: []),
            try! NSRegularExpression(pattern: "-( )?(MAY|JUNE)( )?201(4|6)", options: []),
            try! NSRegularExpression(pattern: "[^ ]*  BC  CA", options: []),
            try! NSRegularExpression(pattern: "#( )?[0-9]{1,5}", options: []),
        ]
    }() // swiftlint:enable force_try

    let csvReader: CSVReader
    let account: Account

    private let commoditySymbol: String
    private let defaultAccountName = "Expenses:TODO"
    private var loaded = false
    private var lines = [CSVLine]()

    init(csvReader: CSVReader, account: Account, commoditySymbol: String) {
        self.csvReader = csvReader
        self.account = account
        self.commoditySymbol = commoditySymbol
    }

    static func new(url: URL?, accountName: String, commoditySymbol: String) -> CSVImporter? {
        guard let url = url, let csvReader = openFile(url), let headerRow = csvReader.headerRow, let account = try? Account(name: accountName) else {
            return nil
        }
        if headerRow == RBCImporter.header {
            return RBCImporter(csvReader: csvReader, account: account, commoditySymbol: commoditySymbol)
        } else if headerRow == TangerineAccountImporter.header {
            return TangerineAccountImporter(csvReader: csvReader, account: account, commoditySymbol: commoditySymbol)
        } else if headerRow == TangerineCardImporter.header {
            return TangerineCardImporter(csvReader: csvReader, account: account, commoditySymbol: commoditySymbol)
        } else if headerRow == LunchOnUsImporter.header {
            return LunchOnUsImporter(csvReader: csvReader, account: account, commoditySymbol: commoditySymbol)
        } else if headerRow == N26Importer.header {
            return N26Importer(csvReader: csvReader, account: account, commoditySymbol: commoditySymbol)
        } else if headerRow == RogersImporter.header {
            return RogersImporter(csvReader: csvReader, account: account, commoditySymbol: commoditySymbol)
        } else if headerRow == SimpliiImporter.header {
            return SimpliiImporter(csvReader: csvReader, account: account, commoditySymbol: commoditySymbol)
        }
        return nil
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

    private func sanitizeDescription(_ description: String) -> String {
        var result = description
        for regex in CSVImporter.regexe {
            result = regex.stringByReplacingMatches(in: result,
                                                    options: .withoutAnchoringBounds,
                                                    range: NSRange(result.startIndex..., in: result),
                                                    withTemplate: "")
        }
        return result
    }

    func loadFile() {
        guard !loaded else {
            return
        }
        while csvReader.next() != nil {
            lines.append(parseLine())
        }
        lines.sort { $0.date > $1.date }
        loaded = true
    }

    func parseLineIntoTransaction() -> ImportedTransaction? {
        guard loaded, let data = lines.popLast() else {
            return nil
        }
        let commodity = Commodity(symbol: commoditySymbol)
        var description = sanitizeDescription(data.description)
        var payee = data.payee
        let originalPayee = payee
        let originalDescription = description
        if let savedPayee = (UserDefaults.standard.dictionary(forKey: CSVImporter.userDefaultsPayees) as? [String: String])?[description] {
            payee = savedPayee
        }
        if let savedDescription = (UserDefaults.standard.dictionary(forKey: CSVImporter.userDefaultsDescription) as? [String: String])?[description] {
            description = savedDescription
        }

        let categoryAmount = Amount(number: -data.amount, commodity: commodity, decimalDigits: 2)
        var categoryAccount = try! Account(name: defaultAccountName) // swiftlint:disable:this force_try
        if let accountName = (UserDefaults.standard.dictionary(forKey: CSVImporter.userDefaultsAccounts) as? [String: String])?[payee],
            let account = try? Account(name: accountName) {
            categoryAccount = account
        }
        let flag: Flag = description == originalDescription && payee == originalPayee ? .incomplete : .complete
        let transactionMetaData = TransactionMetaData(date: data.date, payee: payee, narration: description, flag: flag, tags: [])
        let transaction = Transaction(metaData: transactionMetaData)
        let amount = Amount(number: data.amount, commodity: commodity, decimalDigits: 2)
        transaction.postings.append(Posting(account: account, amount: amount, transaction: transaction))
        if let price = data.price {
            let pricePer = Amount(number: categoryAmount.number / price.number, commodity: categoryAmount.commodity, decimalDigits: 7)
            transaction.postings.append(Posting(account: categoryAccount, amount: price, transaction: transaction, price: pricePer, cost: nil))
        } else {
            transaction.postings.append(Posting(account: categoryAccount, amount: categoryAmount, transaction: transaction))
        }
        return ImportedTransaction(transaction: transaction, originalDescription: originalDescription)
    }

    func parseLine() -> CSVLine { // swiftlint:disable:this unavailable_function
        fatalError("Must Override")
    }

}
