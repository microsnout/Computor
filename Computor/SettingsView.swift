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
    static var settingsPriDispTextSize : String { "settings.priDispTextSize" }
    static var settingsAuxDispTextSize : String { "settings.auxDispTextSize" }
    static var settingsSoftkeyUnits : String { "settings.softkeyUnits" }
    static var settingsKeyCaptions : String { "settings.keyCaptions" }
}

enum SoftkeyUnits: Int, Hashable {
    case mixed = 0, metric, imperial, physics, electrical, navigation
}


struct SettingsView: View {
    @AppStorage(.settingsDarkModeKey)
    private var darkMode = false
    
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false
    
    @AppStorage(.settingsPriDispTextSize)
    private var priDispTextSize = TextSize.normal
    
    @AppStorage(.settingsAuxDispTextSize)
    private var auxDispTextSize = TextSize.normal
    
    @AppStorage(.settingsSoftkeyUnits)
    private var softkeyUnits = SoftkeyUnits.mixed

    @AppStorage(.settingsKeyCaptions)
    private var keyCaptions = true
    
    var body: some View {
        NavigationView {
            List {
                Section( header: Text("Colors").foregroundColor(Color("DisplayText"))  ) {
                    Toggle("Display Dark Mode", isOn: $darkMode)
                }
                .listRowBackground(Color("Display"))
                
                Section( header: Text("Primary Display").foregroundColor(Color("DisplayText"))  ) {
                    Picker( selection: $priDispTextSize, label: Text("Text Size")) {
                        Text("Small").tag(TextSize.small)
                        Text("Medium").tag(TextSize.normal)
                        Text("Large").tag(TextSize.large)
                    }
                    
                }

                Section( header: Text("Auxiliary Display").foregroundColor(Color("DisplayText"))  ) {
                    Picker( selection: $auxDispTextSize, label: Text("Text Size")) {
                        Text("Small").tag(TextSize.small)
                        Text("Medium").tag(TextSize.normal)
                        Text("Large").tag(TextSize.large)
                    }
                }
                
                Section( header: Text("Keyboard").foregroundColor(Color("DisplayText")) ) {
                    
                    Toggle("Serif Font", isOn: $serifFont)

                    Toggle("Key help captions", isOn: $keyCaptions)
                    
                    Picker( selection: $softkeyUnits, label: Text("Unit Keys")) {
                        Text("Default").tag(SoftkeyUnits.mixed)
                        Text("Metric").tag(SoftkeyUnits.metric)
                        Text("Imperial").tag(SoftkeyUnits.imperial)
                        Text("Physics").tag(SoftkeyUnits.physics)
                        Text("Electrical").tag(SoftkeyUnits.electrical)
                        Text("Navigation").tag(SoftkeyUnits.navigation)
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
