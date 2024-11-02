//
//  SettingsView.swift
//  Computor
//
//  Created by Barry Hall on 2024-10-31.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("darkMode") var darkMode = false

    var body: some View {
        Text("Computor Settings")
        
        NavigationView {
            List {
                Section( header: Text("Screen")) {
                    Toggle("Dark Mode", isOn: $darkMode)
                        .onChange(of: darkMode) { oldValue, value in
                            // Update the app's appearance
                            //            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = value ? .dark : .light
                        }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
