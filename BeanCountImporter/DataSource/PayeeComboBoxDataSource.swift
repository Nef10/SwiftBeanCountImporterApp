//
//  PayeeComboBoxDataSource.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2018-02-10.
//  Copyright © 2018 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation
import SwiftBeanCountModel

class PayeeComboBoxDataSource: NSObject {

    private let payees: [String]

    init(ledger: Ledger) {
        payees = Array(Set(ledger.transactions.map { $0.metaData.payee })).filter { !$0.isEmpty }.sorted { $0.lowercased() < $1.lowercased() }
    }

}

extension PayeeComboBoxDataSource: NSComboBoxDataSource {

    func numberOfItems(in comboBox: NSComboBox) -> Int {
        payees.count
    }

    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        payees[index]
    }

    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        payees.firstIndex { $0.lowercased() == string.lowercased() } ?? NSNotFound
    }

    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        payees.first { $0.lowercased().starts(with: string.lowercased()) }
    }

}
