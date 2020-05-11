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

protocol Importer {

    static var settings: [String] { get }

}
