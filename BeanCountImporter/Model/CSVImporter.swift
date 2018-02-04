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
    }

    let csvReader: CSVReader
    let account: Account

    private let commoditySymbol: String
    private let accountName = "Expenses:TODO"

    static private let payees = [
        "Bean Around The": "Bean around the World",
        "Bean Around The World": "Bean around the World",
        "Bean Around The World Coffee": "Bean around the World",
        "Compass Vending": "Translink",
        "Ikea Richmond": "IKEA",
        "Tacofino Yaleto": "Tacofino",
        "Grounds For App": "Grounds For Appeal",
        "The Greek By An": "The Greek By Anatoli",
        "Phat Sports Bar": "PHAT Sports Bar",
        "A&w": "A&W",
        "A&W Store": "A&W",
        "Yaletown Keg": "The Keg",
        "Square One Insu": "SquareOne",
        "Netflix.Com": "Netflix",
        "Yaletown Brewing Co.": "Yaletown Brewing Company",
        "Real Cdn Superstore": "Real Canadian Superstore",
        "H&M Ca -Metropolis": "H&M",
        "Jugo Juice Broadway St": "Jugo Juice",
        "Dairy Queen Orange Jul": "Orange Julius",
        "Earls Yaletown": "Earls",
        "Earl's Fir Street": "Earls",
        "Earls 10120 Yaletown": "Earls",
        "Broadway & Macdonald": "",
        "Fresh Take Out Japanes": "Fresh Sushi",
        "Nero Belgian Waffle Ba": "Nero",
        "Score On Davie": "Score",
        "The Distillery Bar + Kitchen At Yaletown Distilling Company": "Distillery",
        "Phat": "PHAT Sports Bar",
        "Flying Pig Yaletown": "Flying Pig",
        "Boiling Point Burnaby": "Boiling Point",
        "Thirst First Refreshme": "Thirst First",
        "Thirst First Re": "Thirst First",
        "Milk $ Sugar Cafe": "Milk & Sugar Cafe",
        "Safeway": "Safeway",
        "Jugo Juice": "Jugo Juice",
        "Starbucks": "Starbucks",
        "Ebiten": "Ebiten",
        "Mcdonald's": "Mcdonald's",
        "Tim Horton's": "Tim Hortons",
        "Tim Hortons": "Tim Hortons",
        "Mastercuts": "Mastercuts",
        "Fresh Bowl": "Fresh Bowl",
        "Donair Stop": "Donair Stop",
        "Freedom Mobile": "Freedom Mobile",
        "Subway": "Subway",
        "Brooklyn Pizza": "Brooklyn Pizza",
        "Sushi Aji": "Sushi Aji",
        "Cineplex": "Cineplex",
        "Rodney's Oyster House": "Rodney's Oyster House",
        "The Greek By Anatoli": "The Greek By Anatoli",
        "Lickerish": "Lickerish",
        "Delicious Pho": "Delicious Pho",
        "Red Card Sports Bar": "Red Card Sports Bar",
        "Smithe Salad": "Smithe Salad",
        "Grounds For Appeal": "Grounds For Appeal",
        "Cactus Club Cafe": "Cactus Club Cafe",
        "The Parlour": "The Parlour",
        "Yaletown Brewing Company": "Yaletown Brewing Company",
        "Super Chef Grill": "Super Chef Grill",
        "Honjin Sushi": "Honjin Sushi",
        "Freshslice Pizza": "Freshslice Pizza",
        "Super Great Pizza": "Super Great Pizza",
    ]

    static private let accounts = [
        "Safeway": "Expenses:Food:Groceries",
        "Jugo Juice": "Expenses:Food:Snack",
        "Starbucks": "Expenses:Food:Snack",
        "Ebiten": "Expenses:Food:TakeOut",
        "Mcdonald's": "Expenses:Food:FastFood",
        "Tim Hortons": "Expenses:Food:Snack",
        "Tim Horton's": "Expenses:Food:Snack",
        "Mastercuts": "Expenses:Living:Services",
        "Fresh Bowl": "Expenses:Food:TakeOut",
        "Bean around the World": "Expenses:Food:TakeOut",
        "Tacofino": "Expenses:Food:TakeOut",
        "Grounds For Appeal": "Expenses:Food:TakeOut",
        "PHAT Sports Bar": "Expenses:Food:TakeOut",
        "A&W": "Expenses:Food:FastFood",
        "Donair Stop": "Expenses:Food:TakeOut",
        "RBC": "Expenses:FinancialInstitutions",
        "SAP Canada Inc.": "Income:Salary:SAP:LunchOnUs",
        "Freedom Mobile": "Expenses:Communication:MobilePhone:Contract",
        "SquareOne": "Expenses:Insurance:Tenant:SquareOne",
        "Netflix": "Expenses:Leisure:Entertainment:Streaming",
        "Brooklyn Pizza": "Expenses:Food:TakeOut",
        "Sushi Aji": "Expenses:Food:EatingOut",
        "Cineplex": "Expenses:Leisure:Entertainment:Cinema",
        "Tangerine": "Income:FinancialInstitutions:Interests",
        "H&M": "Expenses:Living:Clothes:Clothes",
        "Rodney's Oyster House": "Expenses:Food:EatingOut",
        "Lickerish": "Expenses:Leisure:Entertainment:Party",
        "Delicious Pho": "Expenses:Food:EatingOut",
        "Score": "Expenses:Food:EatingOut",
        "Orange Julius": "Expenses:Food:Snack",
        "Distillery": "Expenses:Food:EatingOut",
        "Smithe Salad": "Expenses:Food:TakeOut",
        "Cactus Club Cafe": "Expenses:Food:EatingOut",
        "Super Chef Grill": "Expenses:Food:TakeOut",
        "Flying Pig": "Expenses:Food:EatingOut",
        "Honjin Sushi": "Expenses:Food:EatingOut",
        "Boiling Point": "Expenses:Food:EatingOut",
        "Thirst First": "Expenses:Food:Snack",
        "Freshslice Pizza": "Expenses:Food:Snack",
        "Milk & Sugar Cafe": "Expenses:Food:Snack",
        "Super Great Pizza": "Expenses:Food:Snack",
    ]

    static private let regexe: [NSRegularExpression] = {
        [ // swiftlint:disable force_try
            try! NSRegularExpression(pattern: "(C-)?IDP PURCHASE( )?-( )?[0-9]{4}", options: []),
            try! NSRegularExpression(pattern: "VISA DEBIT (PUR|REF)-[0-9]{4}", options: []),
            try! NSRegularExpression(pattern: "WWWINTERAC PUR [0-9]{4}", options: []),
            try! NSRegularExpression(pattern: "INTERAC E-TRF- [0-9]{4}", options: []),
            try! NSRegularExpression(pattern: "[0-9]* ~ Internet Withdrawal", options: []),
            try! NSRegularExpression(pattern: "(-)? SAP(?! CANADA)", options: []),
            try! NSRegularExpression(pattern: "-( )?(MAY|JUNE)( )?201(4|6)", options: []),
            try! NSRegularExpression(pattern: "[^ ]*  BC  CA", options: []),
            try! NSRegularExpression(pattern: "#( )?[0-9]{1,5}", options: []),
        ] // swiftlint:enable force_try
    }()

    init(csvReader: CSVReader, account: Account, commoditySymbol: String) {
        self.csvReader = csvReader
        self.account = account
        self.commoditySymbol = commoditySymbol
    }

    func parse() -> [Transaction] {
        var transactions = [Transaction]()
        let commodity = Commodity(symbol: commoditySymbol)
        while csvReader.next() != nil {
            let data = parseLine()
            var description = data.description
            var payee = data.payee
            for regex in CSVImporter.regexe {
                description = regex.stringByReplacingMatches(in: description,
                                                             options: .withoutAnchoringBounds,
                                                             range: NSRange(description.startIndex..., in: description),
                                                             withTemplate: "")
            }
            description = description.replacingOccurrences(of: "&amp;", with: "&").trimmingCharacters(in: .whitespaces).capitalized
            if let name = CSVImporter.payees[description] {
                payee = name
                description = ""
            }
            let transactionMetaData = TransactionMetaData(date: data.date, payee: payee, narration: description, flag: .incomplete, tags: [])
            let transaction = Transaction(metaData: transactionMetaData)
            let amount = Amount(number: data.amount, commodity: commodity, decimalDigits: 2)
            transaction.postings.append(Posting(account: account, amount: amount, transaction: transaction))
            let categoryAmount = Amount(number: -data.amount, commodity: commodity, decimalDigits: 2)
            var categoryAccount = try! Account(name: accountName) // swiftlint:disable:this force_try
            if let accountName = CSVImporter.accounts[payee], let account = try? Account(name: accountName) {
                categoryAccount = account
            }
            transaction.postings.append(Posting(account: categoryAccount, amount: categoryAmount, transaction: transaction))
            transactions.append(transaction)
        }
        return transactions
    }

    func parseLine() -> CSVLine {
        fatalError("Must Override")
    }

    static func new(url: URL?, accountName: String, commoditySymbol: String) -> CSVImporter? {
        guard let url = url, let csvReader = openFile(url), let headerRow = csvReader.headerRow, let account = try? Account(name: accountName) else {
            return nil
        }
        if headerRow == RBCImporter.header {
            return RBCImporter(csvReader: csvReader, account: account, commoditySymbol: commoditySymbol)
        } else if headerRow == TangerineImporter.header {
            return TangerineImporter(csvReader: csvReader, account: account, commoditySymbol: commoditySymbol)
        } else if headerRow == LunchOnUsImporter.header {
            return LunchOnUsImporter(csvReader: csvReader, account: account, commoditySymbol: commoditySymbol)
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

}
