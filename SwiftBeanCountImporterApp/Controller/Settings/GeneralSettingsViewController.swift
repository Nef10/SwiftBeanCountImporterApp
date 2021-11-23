//
//  GeneralSettingsViewController.swift
//  SwiftBeanCountImporter
//
//  Created by Steffen Kötte on 2020-05-13.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import Cocoa
import Foundation
import SwiftBeanCountImporter
import UniformTypeIdentifiers

class GeneralSettingsViewController: NSViewController {

    struct SettingsFile: Codable {
        let payees: [String: String]
        let accounts: [String: String]
        let descriptions: [String: String]
        let dateTolerance: String
    }

    @IBAction private func importSettingsButtonPressed(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [UTType(filenameExtension: "json")!]
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
        // Delete all old mappings
        for (description, _) in Settings.allDescriptionMappings {
            Settings.setDescriptionMapping(key: description, description: nil)
        }
        for (description, _) in Settings.allPayeeMappings {
            Settings.setPayeeMapping(key: description, payee: nil)
        }
        for (description, _) in Settings.allAccountMappings {
            Settings.setAccountMapping(key: description, account: nil)
        }

        // Set new once
        for (description, newDescriptions) in settingsFile.descriptions {
            Settings.setDescriptionMapping(key: description, description: newDescriptions)
        }
        for (description, payee) in settingsFile.payees {
            Settings.setPayeeMapping(key: description, payee: payee)
        }
        for (description, account) in settingsFile.accounts {
            Settings.setAccountMapping(key: description, account: account)
        }
        if let dateTolerance = Int(settingsFile.dateTolerance) {
            Settings.dateToleranceInDays = dateTolerance
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
        SettingsFile(payees: Settings.allPayeeMappings,
                     accounts: Settings.allAccountMappings,
                     descriptions: Settings.allDescriptionMappings,
                     dateTolerance: "\(Settings.dateToleranceInDays)")
    }

    private func showError(text: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.messageText = text
        alert.beginSheetModal(for: view.window!, completionHandler: nil)
    }

}
