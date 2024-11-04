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
        NavigationView {
            List {
                Section( header: Text("Screen")) {
                    Toggle("Dark Mode", isOn: $darkMode)
                    Toggle("Serif Font", isOn: $serifFont)
                }
            }
            .background(Color("Background"))
        }
        .navigationBarTitle("Settings")
    }
}

//#Preview {
//    SettingsView()
//}
