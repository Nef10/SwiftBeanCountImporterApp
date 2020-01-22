//
//  ManuLifeImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2019-09-08.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

import Foundation
import SwiftBeanCountModel

class ManuLifeImporter {

    private struct ManuLifeBalance {
        let commodity: String
        let unitValue: String
        let employeeBasic: String?
        let employeeVoluntary: String?
        let employerMatch: String?
        let employerBasic: String?
        let memberVoluntary: String?
    }

    private struct ManuLifeBuy {
        let commodity: String
        let units: String
        let price: String
    }

    /// DateFormatter for printing a date in the result string
    private static let printDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    /// DateFormatter to parse the date from the input
    private static let importDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MMMM d, yyyy"
        return dateFormatter
    }()

    private let autocompleteLedger: Ledger?
    private let accountString: String
    private let commodityString: String
    private let commodityPaddingLength = 20
    private let accountPaddingLength = 69
    private let amountPaddingLength = 9
    private let unitFormat = "%.5f"

    // Temporary: Figure out how to input this
    private let cashAccountName = "Parking"
    private let amountString = "0.00"
    private let employeeBasicFraction = 2.0
    private let employerBasicFraction = 2.5
    private let employerMatchFraction = 2.5
    private let employeeVoluntaryFraction = 0.5

    init(autocompleteLedger: Ledger?, accountName: String, commodityString: String) {
        self.autocompleteLedger = autocompleteLedger
        self.accountString = accountName
        self.commodityString = commodityString
    }

    func parse(transaction: String, balance: String) -> String {
        var commodities = autocompleteLedger?.commodities.reduce(into: [String: String]()) {
            if let name = $1.name {
                $0[name] = $1.symbol
            }
        } ?? [:]
        // Temporary till parser can read names
        commodities.merge([
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
        ]) { current, _ in current }
        var result = ""
        if !transaction.isEmpty {
            result = parse(transaction: transaction, commodities: commodities)
        }
        if !balance.isEmpty {
            result += "\n\n\(parse(balance: balance, commodities: commodities))"
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parse(balance: String, commodities: [String: String]) -> String {
        stringifyBalances(parseBalances(balance, commodities))
    }

    private func parse(transaction: String, commodities: [String: String]) -> String {
        stringifyPurchase(parsePurchase(transaction, commodities))
    }

    /// Parses a string into ManuLifeBalances
    ///
    /// - Parameters:
    ///   - string: input from website
    ///   - commodities: dictionary of name to account for commodities
    /// - Returns: ManuLifeBalances
    private func parseBalances(_ string: String, _ commodities: [String: String]) -> [ManuLifeBalance] {

        // RegEx
        let commodityPattern = #"\s*?(\d{4}\s*?-\s*?.*?[a-z]\d)\s*?$"#
        let employeeBasicPattern = #"\s*?Employee Basic\s*([0-9.]*)"#
        let employeeVoluntaryPattern = #"\s*?Employee voluntary\s*([0-9.]*)"#
        let employerBasicPattern = #"\s*?Employer Basic\s*([0-9.]*)"#
        let employerMatchPattern = #"\s*?Employer Match\s*([0-9.]*)"#
        let memberVoluntaryPattern = #"\s*?Member Voluntary\s*([0-9.]*)"#
        let unitValuePattern = #"\s*?(?:Employer Basic|Member Voluntary)\s*[0-9.]*\s*([0-9.]*)\s*[0-9.]*"#

        //swiftlint:disable force_try
        let commodityRegex = try! NSRegularExpression(pattern: commodityPattern, options: [.anchorsMatchLines])
        let employeeBasicRegex = try! NSRegularExpression(pattern: employeeBasicPattern, options: [.anchorsMatchLines])
        let employeeVoluntaryRegex = try! NSRegularExpression(pattern: employeeVoluntaryPattern, options: [.anchorsMatchLines])
        let employerBasicRegex = try! NSRegularExpression(pattern: employerBasicPattern, options: [.anchorsMatchLines])
        let employerMatchRegex = try! NSRegularExpression(pattern: employerMatchPattern, options: [.anchorsMatchLines])
        let memberVoluntaryRegex = try! NSRegularExpression(pattern: memberVoluntaryPattern, options: [.anchorsMatchLines])
        let unitValueRegex = try! NSRegularExpression(pattern: unitValuePattern, options: [.anchorsMatchLines])
        //swiftlint:enable force_try

        // Split by different Commodities
        let splittedInput = string.components(separatedBy: "TOTAL")

        // Get different Accounts for each Commodity
        var results = [ManuLifeBalance]()
        for input in splittedInput {
            guard var commodity = firstMatch(in: input, regex: commodityRegex), let unitValue = firstMatch(in: input, regex: unitValueRegex) else {
                continue
            }
            commodity = commodity.replacingOccurrences(of: " -", with: "")
            commodity = commodities[commodity] ?? commodity
            results.append(ManuLifeBalance(commodity: commodity,
                                           unitValue: unitValue,
                                           employeeBasic: firstMatch(in: input, regex: employeeBasicRegex),
                                           employeeVoluntary: firstMatch(in: input, regex: employeeVoluntaryRegex),
                                           employerMatch: firstMatch(in: input, regex: employerMatchRegex),
                                           employerBasic: firstMatch(in: input, regex: employerBasicRegex),
                                           memberVoluntary: firstMatch(in: input, regex: memberVoluntaryRegex)))
        }

        return results
    }

    /// Creates a string out of ManuLifeBalances
    ///
    /// - Parameter balances: Array of ManuLifeBalance
    /// - Returns: string with the balances and prices of the units at the current date
    private func stringifyBalances(_ balances: [ManuLifeBalance]) -> String {
        let dateString = Self.printDateFormatter.string(from: Date())

        return balances.map {
            var result = [String]()
            if let employeeBasic = $0.employeeBasic {
                let accountName = "\(accountString):Employee:Basic:\($0.commodity)".padding(toLength: accountPaddingLength, withPad: " ", startingAt: 0)
                result.append("\(dateString) balance \(accountName) \(leftPadding(toLength: amountPaddingLength, withPad: " ", string: employeeBasic)) \($0.commodity)")
            }
            if let employerBasic = $0.employerBasic {
                let accountName = "\(accountString):Employer:Basic:\($0.commodity)".padding(toLength: accountPaddingLength, withPad: " ", startingAt: 0)
                result.append("\(dateString) balance \(accountName) \(leftPadding(toLength: amountPaddingLength, withPad: " ", string: employerBasic)) \($0.commodity)")
            }
            if let employerMatch = $0.employerMatch {
                let accountName = "\(accountString):Employer:Match:\($0.commodity)".padding(toLength: accountPaddingLength, withPad: " ", startingAt: 0)
                result.append("\(dateString) balance \(accountName) \(leftPadding(toLength: amountPaddingLength, withPad: " ", string: employerMatch)) \($0.commodity)")
            }
            if let employeeVoluntary = $0.employeeVoluntary {
                let accountName = "\(accountString):Employee:Voluntary:\($0.commodity)".padding(toLength: accountPaddingLength, withPad: " ", startingAt: 0)
                result.append("\(dateString) balance \(accountName) \(leftPadding(toLength: amountPaddingLength, withPad: " ", string: employeeVoluntary)) \($0.commodity)")
            }
            if let memberVoluntary = $0.memberVoluntary {
                let accountName = "\(accountString):\($0.commodity.components(separatedBy: "_")[0])".padding(toLength: accountPaddingLength, withPad: " ", startingAt: 0)
                result.append("\(dateString) balance \(accountName) \(leftPadding(toLength: amountPaddingLength, withPad: " ", string: memberVoluntary)) \($0.commodity)")
            }
            return result.joined(separator: "\n")
        }
        .joined(separator: "\n") + "\n\n" + balances.map {
            "\(dateString) price \($0.commodity.padding(toLength: commodityPaddingLength, withPad: " ", startingAt: 0)) \($0.unitValue) \(commodityString)"
        }
        .sorted()
        .joined(separator: "\n")
    }

    /// Parses a string into ManuLifeBuys
    ///
    /// - Parameters:
    ///   - string: input from website
    ///   - commodities: dictionary of name to account for commodities
    /// - Returns: Tupel with ManuLifeBuys and a date
    private func parsePurchase(_ input: String, _ commodities: [String: String]) -> ([ManuLifeBuy], Date?) {

        // RegEx
        let datePattern = #"^(.*) Contribution \(Ref."#
        let purchasePattern = #"\s*.*?\.gif\s*(\d{4}.*?[a-z]\d)\s*$\s*Contribution\s*([0-9.]*)\s*units\s*@\s*\$([0-9.]*)/unit\s*[0-9.]*\s*$"#

        //swiftlint:disable force_try
        let dateRegex = try! NSRegularExpression(pattern: datePattern, options: [.anchorsMatchLines])
        let regex = try! NSRegularExpression(pattern: purchasePattern, options: [.anchorsMatchLines])
        //swiftlint:enable force_try

        // Parse purchase date
        let parsedDate = firstMatch(in: input, regex: dateRegex) ?? ""
        let date = Self.importDateFormatter.date(from: parsedDate)

        // Parse purchased units
        let fullRange = NSRange(input.startIndex..<input.endIndex, in: input)
        return (regex.matches(in: input, options: [], range: fullRange).compactMap { result -> ManuLifeBuy? in
            guard result.numberOfRanges == 4 else {
                return nil
            }
            var strings = [String]()
            for rangeNumber in 1..<result.numberOfRanges {
                let matchRange = result.range(at: rangeNumber)
                guard matchRange.location != NSNotFound, let range = Range(matchRange, in: input) else {
                    return nil
                }
                strings.append("\(input[range])")
            }
            let commodity = commodities[strings[0]] ?? strings[0]
            return ManuLifeBuy(commodity: commodity, units: strings[1], price: strings[2])
        }, date)
    }

    /// Creates a string out of ManuLifeBuys and a date
    ///
    /// - Parameter purchase: tupel with array of ManuLifeBuy and a date
    /// - Returns: string with the purchase and prices of the units at the purchase date
    private func stringifyPurchase(_ purchase: ([ManuLifeBuy], Date?)) -> String {
        let (matches, date) = purchase
        let dateString = date != nil ? Self.printDateFormatter.string(from: date!) : ""

        var decimalPointPosition = 0
        if let index = amountString.range(of: ".")?.lowerBound {
            decimalPointPosition = amountString.distance(from: amountString.startIndex, to: index)
        }

        let cashAccount = "\(accountString):\(cashAccountName)".padding(toLength: accountPaddingLength - decimalPointPosition + 1, withPad: " ", startingAt: 0)

        var result = "\(dateString) * \"\" \"\"\n  \(cashAccount) \(amountString.padding(toLength: 10, withPad: " ", startingAt: 0)) \(commodityString)\n"
        result += matches.map {
            let employeeBasic = "\(accountString):Employee:Basic:\($0.commodity)".padding(toLength: accountPaddingLength, withPad: " ", startingAt: 0)
            let employerBasic = "\(accountString):Employer:Basic:\($0.commodity)".padding(toLength: accountPaddingLength, withPad: " ", startingAt: 0)
            let employerMatch = "\(accountString):Employer:Match:\($0.commodity)".padding(toLength: accountPaddingLength, withPad: " ", startingAt: 0)
            let employeeVoluntary = "\(accountString):Employee:Voluntary:\($0.commodity)".padding(toLength: accountPaddingLength, withPad: " ", startingAt: 0)
            let unitFraction = Double($0.units)! / (employeeBasicFraction + employerBasicFraction + employerMatchFraction + employeeVoluntaryFraction)
            let commodity = $0.commodity.padding(toLength: commodityPaddingLength, withPad: " ", startingAt: 0)
            var result = "  \(employeeBasic) \(String(format: unitFormat, unitFraction * employeeBasicFraction)) \(commodity) {\($0.price) \(commodityString)}\n"
            result += "  \(employerBasic) \(String(format: unitFormat, unitFraction * employerBasicFraction)) \(commodity) {\($0.price) \(commodityString)}\n"
            result += "  \(employerMatch) \(String(format: unitFormat, unitFraction * employerMatchFraction)) \(commodity) {\($0.price) \(commodityString)}\n"
            result += "  \(employeeVoluntary) \(String(format: unitFormat, unitFraction * employeeVoluntaryFraction)) \(commodity) {\($0.price) \(commodityString)}"
            return result
        }
        .joined(separator: "\n")
        result += "\n\n"
        result += matches.map { buy -> String in
            "\(dateString) price \(buy.commodity.padding(toLength: commodityPaddingLength, withPad: " ", startingAt: 0)) \(buy.price) \(commodityString)"
        }
        .sorted()
        .joined(separator: "\n")
        return result
    }

    /// Pads a string to a certain length with a given character
    ///
    /// Note: If the string is longer than the padding the original string is returned
    ///
    /// - Parameters:
    ///   - toLength: length the string should be extended to
    ///   - character: character used for filling
    ///   - string: string to pad
    /// - Returns: padded string if the string is shorter than the length, otherwise the original string
    private func leftPadding(toLength: Int, withPad character: Character, string: String) -> String {
        let length = string.count
        if length < toLength {
            return String(repeatElement(character, count: toLength - length)) + string
        }
        return string
    }

    /// Returns the first match of the capture group regex in the input string
    ///
    /// Checks that there is exactly one capture group.
    ///
    /// - Parameters:
    ///   - input: string to run regex on
    ///   - regex: regex
    /// - Returns: result of the capture group if found, nil otherwise
    private func firstMatch(in input: String, regex: NSRegularExpression) -> String? {
        let captureGroups = 1
        let fullRange = NSRange(input.startIndex..<input.endIndex, in: input)
        guard let result = regex.firstMatch(in: input, options: [], range: fullRange), result.numberOfRanges == 1 + captureGroups else {
            return nil
        }
        let captureGroupRange = result.range(at: captureGroups)
        guard captureGroupRange.location != NSNotFound, let range = Range(captureGroupRange, in: input) else {
            return nil
        }
        return "\(input[range])"
    }

}
