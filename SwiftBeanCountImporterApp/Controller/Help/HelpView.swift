//
//  HelpView.swift
//  SwiftBeanCountImporterApp
//
//  Created by Steffen Koette on 2021-09-13.
//  Copyright © 2021 Steffen Kötte. All rights reserved.
//

import SwiftBeanCountImporter
import SwiftUI

struct HelpTextView: View {
    let content: String

    var body: some View {
        ScrollView {
            Text(content).padding()
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct HelpView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Importers")) {
                    ForEach(0..<ImporterFactory.allImporters.count) { index in
                        NavigationLink(destination: HelpTextView(content: ImporterFactory.allImporters[index].helpText)) {
                            Text(ImporterFactory.allImporters[index].importerName)
                        }
                    }
                }
            }.listStyle(SidebarListStyle())
            Text("Select an importer to see its help text.").frame(maxWidth: .infinity, maxHeight: .infinity)
        }.frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity, minHeight: 300, idealHeight: 500, maxHeight: .infinity, alignment: .center)
    }
}

struct HelpTextView_Previews: PreviewProvider {
    static var previews: some View {
        HelpTextView(content: "ABC\ndef\n\ngh").previewLayout(.sizeThatFits)
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
