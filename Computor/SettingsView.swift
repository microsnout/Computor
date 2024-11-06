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
                Section( header: Text("Screen").foregroundColor(Color("DisplayText"))  ) {
                    Toggle("Dark Mode", isOn: $darkMode)
                    Toggle("Serif Font", isOn: $serifFont)
                }
                .listRowBackground(Color("Display"))
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
