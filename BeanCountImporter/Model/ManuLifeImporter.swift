//
//  ManuLifeImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2019-09-08.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

//swiftlint:disable line_length force_try function_body_length

import Foundation
import SwiftBeanCountModel

class ManuLifeImporter {

    private let autocompleteLedger: Ledger?
    private let accountString: String
    private let commodityString: String
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
        return parseBalance(balance, commodities)
    }

    private func parse(transaction: String, commodities: [String: String]) -> String {
        return parsePurchase(transaction, commodities)
    }

    // MARK: - old code

    private struct Buy {
        let commodity: String
        let units: String
        let price: String
    }

    private struct Balance {
        let commodity: String
        let employeeBasic: String
        let employeeVoluntary: String
        let employerMatch: String
        let employerBasic: String
        let unitValue: String
    }

    private func leftPadding(toLength: Int, withPad character: Character, string: String) -> String {
        let length = string.count
        if length < toLength {
            return String(repeatElement(character, count: toLength - length)) + string
        }
        return string
    }

    private func parseBalance(_ fullInput: String, _ commodities: [String: String]) -> String {
        let splittedInput = fullInput.components(separatedBy: "TOTAL")
        let commodityPattern = #"""
\s*?(\d{4}\s*?-\s*?.*?[a-z]\d)\s*?$
"""#
        let employeeBasicPattern = #"""
\s*?Employee Basic\s*([0-9.]*)
"""#
        let employeeVoluntaryPattern = #"""
\s*?Employee voluntary\s*([0-9.]*)
"""#
        let employerBasicPattern = #"""
\s*?Employer Basic\s*([0-9.]*)
"""#
        let employerMatchPattern = #"""
\s*?Employer Match\s*([0-9.]*)
"""#
        let unitValuePattern = #"""
\s*?Employer Basic\s*[0-9.]*\s*([0-9.]*)\s*[0-9.]*
"""#
        let commodityRegex = try! NSRegularExpression(pattern: commodityPattern, options: [.anchorsMatchLines])
        let employeeBasicRegex = try! NSRegularExpression(pattern: employeeBasicPattern, options: [.anchorsMatchLines])
        let employeeVoluntaryRegex = try! NSRegularExpression(pattern: employeeVoluntaryPattern, options: [.anchorsMatchLines])
        let employerBasicRegex = try! NSRegularExpression(pattern: employerBasicPattern, options: [.anchorsMatchLines])
        let employerMatchRegex = try! NSRegularExpression(pattern: employerMatchPattern, options: [.anchorsMatchLines])
        let unitValueRegex = try! NSRegularExpression(pattern: unitValuePattern, options: [.anchorsMatchLines])
        var results = [Balance]()
        for input in splittedInput {
            guard var commodity = result(input: input, regex: commodityRegex, groups: 1) else {
                continue
            }
            commodity = commodity.replacingOccurrences(of: " -", with: "")
            commodity = commodities[commodity] ?? commodity
            guard let employeeBasic = result(input: input, regex: employeeBasicRegex, groups: 1) else {
                continue
            }
            guard let employeeVoluntary = result(input: input, regex: employeeVoluntaryRegex, groups: 1) else {
                continue
            }
            guard let employerBasic = result(input: input, regex: employerBasicRegex, groups: 1) else {
                continue
            }
            guard let employerMatch = result(input: input, regex: employerMatchRegex, groups: 1) else {
                continue
            }
            guard let unitValue = result(input: input, regex: unitValueRegex, groups: 1) else {
                continue
            }
            results.append(Balance(commodity: commodity, employeeBasic: employeeBasic, employeeVoluntary: employeeVoluntary, employerMatch: employerMatch, employerBasic: employerBasic, unitValue: unitValue))
        }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return results.map { balance -> String in
            "\(dateString) balance Assets:Retirement:ManuLife:DCPP:Employee:Basic:\(balance.commodity.padding(toLength: 23, withPad: " ", startingAt: 0))\(leftPadding(toLength: 8, withPad: " ", string: balance.employeeBasic)) \(balance.commodity)\n\(dateString) balance Assets:Retirement:ManuLife:DCPP:Employer:Basic:\(balance.commodity.padding(toLength: 23, withPad: " ", startingAt: 0))\(leftPadding(toLength: 8, withPad: " ", string: balance.employerBasic)) \(balance.commodity)\n\(dateString) balance Assets:Retirement:ManuLife:DCPP:Employer:Match:\(balance.commodity.padding(toLength: 23, withPad: " ", startingAt: 0))\(leftPadding(toLength: 8, withPad: " ", string: balance.employerMatch)) \(balance.commodity)\n\(dateString) balance Assets:Retirement:ManuLife:DCPP:Employee:Voluntary:\(balance.commodity.padding(toLength: 19, withPad: " ", startingAt: 0))\(leftPadding(toLength: 8, withPad: " ", string: balance.employeeVoluntary)) \(balance.commodity)"
        }.joined(separator: "\n") + "\n\n" +
            results.map { balance -> String in
                "\(dateString) price \(balance.commodity.padding(toLength: 30, withPad: " ", startingAt: 0))\(balance.unitValue) CAD"
            }.sorted().joined(separator: "\n")
    }

    private func result(input: String, regex: NSRegularExpression, groups: Int) -> String? {
        let nsrange = NSRange(input.startIndex..<input.endIndex, in: input)
        guard let result = regex.firstMatch(in: input, options: [], range: nsrange), result.numberOfRanges == groups + 1 else {
            return nil
        }
        let nsrange1 = result.range(at: 1)
        guard nsrange1.location != NSNotFound, let range = Range(nsrange1, in: input) else {
            return nil
        }
        return "\(input[range])"
    }

    private func parsePurchase(_ input: String, _ commodities: [String: String]) -> String {

        var dateResult = ""
        let datePattern = #"""
^(.*) Contribution \(Ref.
"""#
        let dateRegex = try! NSRegularExpression(pattern: datePattern, options: [.anchorsMatchLines])
        let nsrange = NSRange(input.startIndex..<input.endIndex, in: input)
        if let match = dateRegex.firstMatch(in: input, options: [], range: nsrange), match.numberOfRanges == 2 {
            let nsrange = match.range(at: 1)
            if nsrange.location != NSNotFound, let range = Range(nsrange, in: input) {
                dateResult = "\(input[range])"
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let date = dateFormatter.date(from: dateResult)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var dateString = ""
        if let date = date {
            dateString = dateFormatter.string(from: date)
        }

        let pattern = #"""
\s*.*?\.gif\s*(\d{4}.*?[a-z]\d)\s*$\s*Contribution\s*([0-9.]*)\s*units\s*@\s*\$([0-9.]*)/unit\s*[0-9.]*\s*$
"""#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
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
            "  Assets:Retirement:ManuLife:DCPP:Employee:Basic:\(buy.commodity.padding(toLength: 23, withPad: " ", startingAt: 0))\(String(format: "%.5f", Double(buy.units)! / 7.5 * 2.0)) \(buy.commodity.padding(toLength: 18, withPad: " ", startingAt: 0)) {\(buy.price) CAD}\n  Assets:Retirement:ManuLife:DCPP:Employer:Basic:\(buy.commodity.padding(toLength: 23, withPad: " ", startingAt: 0))\(String(format: "%.5f", Double(buy.units)! / 7.5 * 2.5)) \(buy.commodity.padding(toLength: 18, withPad: " ", startingAt: 0)) {\(buy.price) CAD}\n  Assets:Retirement:ManuLife:DCPP:Employer:Match:\(buy.commodity.padding(toLength: 23, withPad: " ", startingAt: 0))\(String(format: "%.5f", Double(buy.units)! / 7.5 * 2.5)) \(buy.commodity.padding(toLength: 18, withPad: " ", startingAt: 0)) {\(buy.price) CAD}\n  Assets:Retirement:ManuLife:DCPP:Employee:Voluntary:\(buy.commodity.padding(toLength: 19, withPad: " ", startingAt: 0))\(String(format: "%.5f", Double(buy.units)! / 7.5 * 0.5)) \(buy.commodity.padding(toLength: 18, withPad: " ", startingAt: 0)) {\(buy.price) CAD}"
        }.joined(separator: "\n") + "\n\n" +
            matches.map { buy -> String in
                "\(dateString) price \(buy.commodity.padding(toLength: 30, withPad: " ", startingAt: 0))\(buy.price) CAD"
            }.sorted().joined(separator: "\n")
    }

}
