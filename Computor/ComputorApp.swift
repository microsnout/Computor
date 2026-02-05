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
    
    @State private var model = CalculatorModel()
    
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
                .environment(model)
                .preferredColorScheme( darkMode ? .dark : .light)
                .accentColor( Color("MenuIcon"))
        }
    }
}
