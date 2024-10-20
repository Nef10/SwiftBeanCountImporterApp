//
//  AccountComboBoxDataSource.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2018-02-10.
//  Copyright © 2018 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation
import SwiftBeanCountModel

class AccountComboBoxDataSource: NSObject {

    private let accounts: [Account]

    init(ledger: Ledger) {
        accounts = ledger.accounts.sorted { $0.name.fullName < $1.name.fullName }
    }

}

extension AccountComboBoxDataSource: NSComboBoxDataSource {

    func numberOfItems(in _: NSComboBox) -> Int {
        accounts.count
    }

    func comboBox(_: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        accounts[index].name
    }

    func comboBox(_: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        accounts.firstIndex { $0.name.fullName == string } ?? NSNotFound
    }

    func comboBox(_: NSComboBox, completedString string: String) -> String? {
        guard let name = (accounts.first { $0.name.fullName.starts(with: string) }?.name) else {
            return ""
        }
        var result = ""
        for group in name.fullName.split(separator: ":") {
            if !result.isEmpty {
                result.append(":")
            }
            result.append(String(group))
            if result.count > string.count {
                break
            }
        }
        return result
    }

}
