//
//  GeneralSettingsViewController.swift
//  BeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-13.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation

class GeneralSettingsViewController: NSViewController {

    struct SettingsFile: Codable {
        let payees: [String: String]
        let accounts: [String: String]
        let descriptions: [String: String]
        let dateTolerance: String
        let importerSettings: [String: String]
    }

    @IBAction private func importSettingsButtonPressed(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["json"]
        openPanel.begin { [weak self] response in
            if response == .OK {
                guard let fileURL = openPanel.url else {
                    return
                }
                let result = self?.readSettingsFile(url: fileURL)
                switch result {
                case let .success(settingsFile):
                    self?.apply(settingsFile: settingsFile)
                case let .failure(error):
                    self?.showError(text: error.localizedDescription)
                default:
                    break
                }
            }
        }
    }

    @IBAction private func exportSettingsButtonPressed(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "Settings.json"
        savePanel.begin { [weak self] response in
            if response == .OK {
                guard let fileURL = savePanel.url else {
                    return
                }
                let result = self?.writeSettingsFile(to: fileURL)
                if let error = result {
                    self?.showError(text: error.localizedDescription)
                }
            }
        }
    }

    private func readSettingsFile(url: URL) -> Result<SettingsFile, Error> {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(SettingsFile.self, from: data)
            return .success(jsonData)
        } catch {
            return .failure(error)
        }
    }

    private func apply(settingsFile: SettingsFile) {
        UserDefaults.standard.set(settingsFile.payees, forKey: Settings.payeesUserDefaultKey)
        UserDefaults.standard.set(settingsFile.accounts, forKey: Settings.accountsUserDefaultsKey)
        UserDefaults.standard.set(settingsFile.descriptions, forKey: Settings.descriptionUserDefaultsKey)
        UserDefaults.standard.set(settingsFile.dateTolerance, forKey: Settings.dateToleranceUserDefaultsKey)
        for (key, setting) in settingsFile.importerSettings {
            UserDefaults.standard.set(setting, forKey: key)
        }
    }

    private func writeSettingsFile(to url: URL) -> Error? {
        let file = generateSettingsFile()
        switch file {
        case let .success(data):
            do {
                try data.write(to: url)
                return nil
            } catch {
                return error
            }
        case let .failure(error):
            return error
        }
    }

    private func generateSettingsFile() -> Result<Data, Error> {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(generateSettings())
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    private func generateSettings() -> SettingsFile {
        SettingsFile(payees: UserDefaults.standard.dictionary(forKey: Settings.payeesUserDefaultKey) as? [String: String] ?? [:],
                     accounts: UserDefaults.standard.dictionary(forKey: Settings.accountsUserDefaultsKey)  as? [String: String] ?? [:],
                     descriptions: UserDefaults.standard.dictionary(forKey: Settings.descriptionUserDefaultsKey) as? [String: String] ?? [:],
                     dateTolerance: UserDefaults.standard.string(forKey: Settings.dateToleranceUserDefaultsKey) ?? "\(Settings.defaultDateTolerance)",
                     importerSettings: generateImporterSettings())
    }

    private func generateImporterSettings() -> [String: String] {
        var result = [String: String]()
        let importers = ImporterManager.importers
        for importer in importers {
            for setting in importer.settings {
                result[importer.getUserDefaultsKey(for: setting)] = importer.get(setting: setting)
            }
        }
        return result
    }

    private func showError(text: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.messageText = text
        alert.beginSheetModal(for: view.window!, completionHandler: nil)
    }

}
