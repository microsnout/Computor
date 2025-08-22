//
//  DebugView.swift
//  Computor
//
//  Created by Barry Hall on 2025-08-22.
//

import SwiftUI


struct DebugButton: View {
    
    var label: String
    
    var code: () -> Void
    
    var body: some View {
        
        Button {
            code()
        }
        label: {
            Text(label)
                .padding(5)
                .foregroundColor( Color("AccentText") )
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color("Frame"), lineWidth: 2)
                )
        }
    }
}


struct DebugView: View {
    
    @StateObject var model: CalculatorModel
    
    var body: some View {
        
        VStack {
            
            DebugButton( label: "Clear Key Assignments") {
                model.kstate.keyMap.fnRow.removeAll()
                model.saveConfiguration()
            }
            
            DebugButton( label: "Delete All Macros") {
                model.kstate.keyMap.fnRow.removeAll()
                model.aux.macroRec = nil
                model.macroMod.macroTable.removeAll()
                model.saveConfiguration()
            }
        }
    }
}
