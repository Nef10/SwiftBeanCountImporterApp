//
//  ManuLifeImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2019-09-08.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

//swiftlint:disable line_length

import Foundation
import SwiftBeanCountModel

class ManuLifeImporter {

    private let autocompleteLedger: Ledger?
    private let accountString: String
    private let commodityString: String
    private let commodityPaddingLength = 29
    private let amountString = "0.00" // Temporary: Figure out how to input this

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
        return stringifyBalances(parseBalances(balance, commodities))
    }

    private func parse(transaction: String, commodities: [String: String]) -> String {
        return parsePurchase(transaction, commodities)
    }

    // MARK: - old code

    private struct ManuLifeBalance {
        let commodity: String
        let unitValue: String
        let employeeBasic: String?
        let employeeVoluntary: String?
        let employerMatch: String?
        let employerBasic: String?
    }

    static private let printDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    static private let importDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MMMM d, yyyy"
        return dateFormatter
    }()

    private struct Buy {
        let commodity: String
        let units: String
        let price: String
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

    private func parseBalances(_ string: String, _ commodities: [String: String]) -> [ManuLifeBalance] {

        // RegEx
        let commodityPattern = #"\s*?(\d{4}\s*?-\s*?.*?[a-z]\d)\s*?$"#
        let employeeBasicPattern = #"\s*?Employee Basic\s*([0-9.]*)"#
        let employeeVoluntaryPattern = #"\s*?Employee voluntary\s*([0-9.]*)"#
        let employerBasicPattern = #"\s*?Employer Basic\s*([0-9.]*)"#
        let employerMatchPattern = #"\s*?Employer Match\s*([0-9.]*)"#
        let unitValuePattern = #"\s*?Employer Basic\s*[0-9.]*\s*([0-9.]*)\s*[0-9.]*"#

        //swiftlint:disable force_try
        let commodityRegex = try! NSRegularExpression(pattern: commodityPattern, options: [.anchorsMatchLines])
        let employeeBasicRegex = try! NSRegularExpression(pattern: employeeBasicPattern, options: [.anchorsMatchLines])
        let employeeVoluntaryRegex = try! NSRegularExpression(pattern: employeeVoluntaryPattern, options: [.anchorsMatchLines])
        let employerBasicRegex = try! NSRegularExpression(pattern: employerBasicPattern, options: [.anchorsMatchLines])
        let employerMatchRegex = try! NSRegularExpression(pattern: employerMatchPattern, options: [.anchorsMatchLines])
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
            let employeeBasic = firstMatch(in: input, regex: employeeBasicRegex)
            let employeeVoluntary = firstMatch(in: input, regex: employeeVoluntaryRegex)
            let employerBasic = firstMatch(in: input, regex: employerBasicRegex)
            let employerMatch = firstMatch(in: input, regex: employerMatchRegex)
            results.append(ManuLifeBalance(commodity: commodity,
                                           unitValue: unitValue,
                                           employeeBasic: employeeBasic,
                                           employeeVoluntary: employeeVoluntary,
                                           employerMatch: employerMatch,
                                           employerBasic: employerBasic))
        }

        return results
    }

    private func stringifyBalances(_ balances: [ManuLifeBalance]) -> String {

        let dateString = ManuLifeImporter.printDateFormatter.string(from: Date())

        return balances.map {
            var result = [String]()
            if let employeeBasic = $0.employeeBasic {
                let accountName = "\(accountString):Employee:Basic:\($0.commodity)"
                result.append("\(dateString) balance \(accountName.padding(toLength: 69, withPad: " ", startingAt: 0)) \(leftPadding(toLength: 8, withPad: " ", string: employeeBasic)) \($0.commodity)")
            }
            if let employerBasic = $0.employerBasic {
                let accountName = "\(accountString):Employer:Basic:\($0.commodity)"
                result.append("\(dateString) balance \(accountName.padding(toLength: 69, withPad: " ", startingAt: 0)) \(leftPadding(toLength: 8, withPad: " ", string: employerBasic)) \($0.commodity)")
            }
            if let employerMatch = $0.employerMatch {
                let accountName = "\(accountString):Employer:Match:\($0.commodity)"
                result.append("\(dateString) balance \(accountName.padding(toLength: 69, withPad: " ", startingAt: 0)) \(leftPadding(toLength: 8, withPad: " ", string: employerMatch)) \($0.commodity)")
            }
            if let employeeVoluntary = $0.employeeVoluntary {
                let accountName = "\(accountString):Employee:Voluntary:\($0.commodity)"
                result.append("\(dateString) balance \(accountName.padding(toLength: 69, withPad: " ", startingAt: 0)) \(leftPadding(toLength: 8, withPad: " ", string: employeeVoluntary)) \($0.commodity)")
            }
            return result.joined(separator: "\n")
        }.joined(separator: "\n") + "\n\n" +
            balances.map {
                "\(dateString) price \($0.commodity.padding(toLength: commodityPaddingLength, withPad: " ", startingAt: 0)) \($0.unitValue) \(commodityString)"
            }.sorted().joined(separator: "\n")
    }

    private func parsePurchase(_ input: String, _ commodities: [String: String]) -> String {

        var dateResult = ""
        let datePattern = #"^(.*) Contribution \(Ref."#
        let pattern = #"\s*.*?\.gif\s*(\d{4}.*?[a-z]\d)\s*$\s*Contribution\s*([0-9.]*)\s*units\s*@\s*\$([0-9.]*)/unit\s*[0-9.]*\s*$"#

        //swiftlint:disable force_try
        let dateRegex = try! NSRegularExpression(pattern: datePattern, options: [.anchorsMatchLines])
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        //swiftlint:enable force_try

        let nsrange = NSRange(input.startIndex..<input.endIndex, in: input)
        if let match = dateRegex.firstMatch(in: input, options: [], range: nsrange), match.numberOfRanges == 2 {
            let nsrange = match.range(at: 1)
            if nsrange.location != NSNotFound, let range = Range(nsrange, in: input) {
                dateResult = "\(input[range])"
            }
        }

        let date = ManuLifeImporter.importDateFormatter.date(from: dateResult)
        var dateString = ""
        if let date = date {
            dateString = ManuLifeImporter.printDateFormatter.string(from: date)
        }

        let matches = regex.matches(in: input, options: [], range: nsrange).compactMap { result -> Buy? in
            guard result.numberOfRanges == 4 else {
                return nil
            }
            var strings = [String]()
            for rangeNumber in 1..<result.numberOfRanges {
                let nsrange = result.range(at: rangeNumber)
                guard nsrange.location != NSNotFound, let range = Range(nsrange, in: input) else {
                    return nil
                }
                strings.append("\(input[range])")
            }
            return Buy(commodity: commodities[strings[0]] ?? strings[0], units: strings[1], price: strings[2])
        }

        return "\(dateString) * \"\" \"\"\n  \(accountString.padding(toLength: 67, withPad: " ", startingAt: 0))\(amountString.padding(toLength: 10, withPad: " ", startingAt: 0)) \(commodityString)\n" + matches.map { buy -> String in
            "  Assets:Retirement:ManuLife:DCPP:Employee:Basic:\(buy.commodity.padding(toLength: 23, withPad: " ", startingAt: 0))\(String(format: "%.5f", Double(buy.units)! / 7.5 * 2.0)) \(buy.commodity.padding(toLength: 18, withPad: " ", startingAt: 0)) {\(buy.price) \(commodityString)}\n  Assets:Retirement:ManuLife:DCPP:Employer:Basic:\(buy.commodity.padding(toLength: 23, withPad: " ", startingAt: 0))\(String(format: "%.5f", Double(buy.units)! / 7.5 * 2.5)) \(buy.commodity.padding(toLength: 18, withPad: " ", startingAt: 0)) {\(buy.price) \(commodityString)}\n  Assets:Retirement:ManuLife:DCPP:Employer:Match:\(buy.commodity.padding(toLength: 23, withPad: " ", startingAt: 0))\(String(format: "%.5f", Double(buy.units)! / 7.5 * 2.5)) \(buy.commodity.padding(toLength: 18, withPad: " ", startingAt: 0)) {\(buy.price) \(commodityString)}\n  Assets:Retirement:ManuLife:DCPP:Employee:Voluntary:\(buy.commodity.padding(toLength: 19, withPad: " ", startingAt: 0))\(String(format: "%.5f", Double(buy.units)! / 7.5 * 0.5)) \(buy.commodity.padding(toLength: 18, withPad: " ", startingAt: 0)) {\(buy.price) \(commodityString)}"
        }.joined(separator: "\n") + "\n\n" +
            matches.map { buy -> String in
                "\(dateString) price \(buy.commodity.padding(toLength: commodityPaddingLength, withPad: " ", startingAt: 0)) \(buy.price) \(commodityString)"
            }.sorted().joined(separator: "\n")
    }

}
