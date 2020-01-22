//
//  AccountComboBoxDataSource.swift
//  BeanCountImporter
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
        accounts = ledger.accounts.sorted { $0.name < $1.name }
    }

}

extension AccountComboBoxDataSource: NSComboBoxDataSource {

    func numberOfItems(in comboBox: NSComboBox) -> Int {
        accounts.count
    }

    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        accounts[index].name
    }

    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        accounts.firstIndex { $0.name == string } ?? NSNotFound
    }

    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        guard let name = (accounts.first { $0.name.starts(with: string) }?.name) else {
            return ""
        }
        var result = ""
        for group in name.split(separator: ":") {
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
