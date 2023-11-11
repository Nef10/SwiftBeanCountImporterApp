//
//  TagTokenFieldDataSource.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2020-04-05.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation
import SwiftBeanCountModel

class TagTokenFieldDataSource: NSObject {

    private let tags: [String]

    init(ledger: Ledger) {
        tags = ledger.tags.map { $0.name }
    }

}

extension TagTokenFieldDataSource: NSTokenFieldDelegate {

    func tokenField(
        _ tokenField: NSTokenField,
        completionsForSubstring substring: String,
        indexOfToken tokenIndex: Int,
        indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?
    ) -> [Any]? {  // swiftlint:disable:this discouraged_optional_collection
        let string = substring.first == "#" ? String(substring.dropFirst()) : substring
        let filteredTags = tags.filter {
            $0.contains(string)
        }
        if !(filteredTags.first?.starts(with: substring) ?? false) {
            selectedIndex?.pointee = -1
        } else {
            selectedIndex?.pointee = 0
        }
        return filteredTags
    }

}
