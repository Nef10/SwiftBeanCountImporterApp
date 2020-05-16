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

    private(set) var account: Account?
    var ledger: Ledger?

    var commodityString: String {
        Self.get(setting: Self.currencySetting) ?? fallbackCommodity
    }

    init(ledger: Ledger?) {
        self.ledger = ledger
    }

    func possibleAccounts() -> [String] {
        if let account = account {
            return [account.name]
        }
        return accountsFromSettings()
    }

    func useAccount(name: String) throws {
        try self.account = Account(name: name)
    }

    private func accountsFromSettings() -> [String] {
        (Self.get(setting: Self.accountsSetting) ?? "").components(separatedBy: CharacterSet(charactersIn: " ,")).filter { !$0.isEmpty }
    }

}
