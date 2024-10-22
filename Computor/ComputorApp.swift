//
//  ComputorApp.swift
//  Computor
//
//  Created by Barry Hall on 2024-10-22.
//

import SwiftUI

@main
struct ComputorApp: App {
    init() {
        initKeyLayout()
        TypeDef.buildUnitData()
    }
    
    var body: some Scene {
        WindowGroup {
            CalculatorView()
        }
    }
}
