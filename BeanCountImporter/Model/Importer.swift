//
//  Importer.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-10.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Foundation
import SwiftBeanCountModel

enum ImporterManager {
    static var importers: [Importer.Type] {
        FileImporterManager.importers + TextImporterManager.importers
    }
}

struct ImporterSetting {
    let identifier: String
    let name: String
}

protocol Importer {

    static var settingsName: String { get }
    static var settings: [ImporterSetting] { get }

    func possibleAccountNames() -> [AccountName]
    func useAccount(name: AccountName)

}

extension Importer {

    static func get(setting: ImporterSetting) -> String? {
        UserDefaults.standard.string(forKey: getUserDefaultsKey(for: setting))
    }

    static func set(setting: ImporterSetting, to value: String) {
        UserDefaults.standard.set(value, forKey: getUserDefaultsKey(for: setting))
    }

    static func getUserDefaultsKey(for setting: ImporterSetting) -> String {
        "\(String(describing: self)).\(setting.identifier)"
    }

}
