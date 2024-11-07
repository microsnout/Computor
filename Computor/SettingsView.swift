//
//  SettingsView.swift
//  Computor
//
//  Created by Barry Hall on 2024-10-31.
//

import SwiftUI

extension String {
    static var settingsDarkModeKey : String { "settings.darkMode" }
    static var settingsSerifFontKey : String { "settings.serifFont" }
    static var settingsDisplayRows : String { "settings.displayRows" }
}


struct SettingsView: View {
    @AppStorage(.settingsDarkModeKey)
    private var darkMode = false
    
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false
    
    @AppStorage(.settingsDisplayRows)
    private var displayRows = 3

    var body: some View {
        NavigationView {
            List {
                Section( header: Text("Screen").foregroundColor(Color("DisplayText"))  ) {
                    Toggle("Dark Mode", isOn: $darkMode)
                    Toggle("Serif Font", isOn: $serifFont)
                }
                .listRowBackground(Color("Display"))
                
                Section( header: Text("Display").foregroundColor(Color("DisplayText"))  ) {
                    Picker( selection: $displayRows, label: Text("Registers")) {
                        Text("X").tag(1)
                        Text("X, Y").tag(2)
                        Text("X, Y, Z").tag(3)
                        Text("X, Y, Z, T").tag(4)
                    }

                }
            }
            .background(Color("ListBack"))
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitle("Settings")
    }
}

//#Preview {
//    SettingsView()
//}
