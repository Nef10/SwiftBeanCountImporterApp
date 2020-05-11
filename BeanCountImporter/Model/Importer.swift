//
//  Importer.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-10.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Foundation

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
    static var settingsIdentifier: String { get }
    static var settings: [ImporterSetting] { get }

}

extension Importer {

    static func get(setting: ImporterSetting) -> String? {
        UserDefaults.standard.string(forKey: "\(Self.settingsIdentifier).\(setting.identifier)")
    }

    static func set(setting: ImporterSetting, to value: String) {
        UserDefaults.standard.set(value, forKey: "\(Self.settingsIdentifier).\(setting.identifier)")
    }

}
