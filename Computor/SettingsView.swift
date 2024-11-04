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
}


struct SettingsView: View {
    @AppStorage(.settingsDarkModeKey)
    private var darkMode = false
    
    @AppStorage(.settingsSerifFontKey)
    private var serifFont = false

    var body: some View {
        Text("Computor Settings")
        
        NavigationView {
            List {
                Section( header: Text("Screen")) {
                    Toggle("Dark Mode", isOn: $darkMode)
                        .onChange(of: darkMode) { oldValue, value in
//                            UIWindowScene.windows.first?.overrideUserInterfaceStyle = value ? .dark : .light
                        }
                    Toggle("Serif Font", isOn: $serifFont)
                        .onChange(of: serifFont) { oldValue, value in
                        }
                }
            }
        }
    }
}

//#Preview {
//    SettingsView()
//}
