//
//  CSVBaseImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-10.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import CSV
import Foundation
import SwiftBeanCountModel

class CSVBaseImporter {

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
    let commoditySymbol: String

    private var loaded = false
    private var lines = [CSVLine]()

    required init(csvReader: CSVReader, account: Account, commoditySymbol: String) {
        self.csvReader = csvReader
        self.account = account
        self.commoditySymbol = commoditySymbol
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
        if let savedPayee = (UserDefaults.standard.dictionary(forKey: Settings.userDefaultsPayees) as? [String: String])?[description] {
            payee = savedPayee
        }
        if let savedDescription = (UserDefaults.standard.dictionary(forKey: Settings.userDefaultsDescription) as? [String: String])?[description] {
            description = savedDescription
        }

        let categoryAmount = Amount(number: -data.amount, commodity: commodity, decimalDigits: 2)
        var categoryAccount = try! Account(name: Settings.defaultAccountName) // swiftlint:disable:this force_try
        if let accountName = (UserDefaults.standard.dictionary(forKey: Settings.userDefaultsAccounts) as? [String: String])?[payee],
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

    private func sanitizeDescription(_ description: String) -> String {
        var result = description
        for regex in Self.regexe {
            result = regex.stringByReplacingMatches(in: result,
                                                    options: .withoutAnchoringBounds,
                                                    range: NSRange(result.startIndex..., in: result),
                                                    withTemplate: "")
        }
        return result
    }

}
