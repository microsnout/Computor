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
    static var settingsPriDispTextSize : String { "settings.priDispTextSize" }
    static var settingsAuxDispTextSize : String { "settings.auxDispTextSize" }
}


struct SettingsView: View {
    @AppStorage(.settingsDarkModeKey)
    private var darkMode = false
    
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false
    
    @AppStorage(.settingsDisplayRows)
    private var displayRows = 3
    
    @AppStorage(.settingsPriDispTextSize)
    private var priDispTextSize = TextSize.normal
    
    @AppStorage(.settingsAuxDispTextSize)
    private var auxDispTextSize = TextSize.normal

    var body: some View {
        NavigationView {
            List {
                Section( header: Text("Screen").foregroundColor(Color("DisplayText"))  ) {
                    Toggle("Dark Mode", isOn: $darkMode)
                    Toggle("Serif Font", isOn: $serifFont)
                }
                .listRowBackground(Color("Display"))
                
                Section( header: Text("Primary Display").foregroundColor(Color("DisplayText"))  ) {
                    Picker( selection: $priDispTextSize, label: Text("Text Size")) {
                        Text("Small").tag(TextSize.small)
                        Text("Medium").tag(TextSize.normal)
                        Text("Large").tag(TextSize.large)
                    }
                    
                    Picker( selection: $displayRows, label: Text("Registers")) {
                        Text("X").tag(1)
                        Text("X, Y").tag(2)
                        Text("X, Y, Z").tag(3)
                        Text("X, Y, Z, T").tag(4)
                    }

                }
                
                Section( header: Text("Auxiliary Display").foregroundColor(Color("DisplayText"))  ) {
                    Picker( selection: $auxDispTextSize, label: Text("Text Size")) {
                        Text("Small").tag(TextSize.small)
                        Text("Medium").tag(TextSize.normal)
                        Text("Large").tag(TextSize.large)
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
