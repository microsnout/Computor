//
//  ComputorApp.swift
//  Computor
//
//  Created by Barry Hall on 2024-10-22.
//  Restored project
//

import SwiftUI

@main
struct ComputorApp: App {
    
    @AppStorage(.settingsDarkModeKey)
    private var darkMode = false
    
    init() {
        initKeyLayout()
        UnitDef.buildStdUnitData()
        TypeDef.buildStdTypeData()

        // Install Library Functions
        installFunctions()
    }
    
    var body: some Scene {
        WindowGroup {
            CalculatorView()
                .preferredColorScheme( darkMode ? .dark : .light)
                .accentColor( Color("MenuIcon"))
        }
    }
}
