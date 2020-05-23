//
//  BaseImporter.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-14.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Foundation
import SwiftBeanCountModel

class BaseImporter: Importer {

    static let currencySetting = ImporterSetting(identifier: "currency", name: "Currency")
    static let accountsSetting = ImporterSetting(identifier: "accounts", name: "Account(s)")

    class var settingsName: String { "" }
    class var settings: [ImporterSetting] { [currencySetting, accountsSetting] }

    private let fallbackCommodity = "CAD"

    private(set) var accountName: AccountName?
    var ledger: Ledger?

    var commodityString: String {
        Self.get(setting: Self.currencySetting) ?? fallbackCommodity
    }

    init(ledger: Ledger?) {
        self.ledger = ledger
    }

    func possibleAccountNames() -> [AccountName] {
        if let accountName = accountName {
            return [accountName]
        }
        return accountsFromSettings()
    }

    func useAccount(name: AccountName) {
        self.accountName = name
    }

    private func accountsFromSettings() -> [AccountName] {
        (Self.get(setting: Self.accountsSetting) ?? "").components(separatedBy: CharacterSet(charactersIn: " ,")).map { try? AccountName($0) }.compactMap { $0 }
    }

}
