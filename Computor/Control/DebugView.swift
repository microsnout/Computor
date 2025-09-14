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
                model.aux.macroMod.deleteAll()
                model.saveConfiguration()
            }
            
            DebugButton( label: "Delete ALL Module files") {
                
                
                let modDir = Database.moduleDirectoryURL()
                
                deleteAllFiles(in: modDir)
                
                model.kstate.keyMap.fnRow.removeAll()
                model.aux.macroRec = nil
                
                if let mfr0 = model.db.indexFile.mfileTable.first(where: { $0.isModZero }) {
                    
                    mfr0.mfile = ModuleFile(mfr0)
                    model.aux.macroMod = mfr0
                    model.db.saveModule(mfr0)
                }
                
                model.db.indexFile.mfileTable.removeAll( where: { !$0.isModZero } )
                model.db.saveIndex()
            }

            
            DebugButton( label: "Print Key Maps" ) {
                
                print("Key Map:")
                for (key, tag) in model.kstate.keyMap.fnRow {
                    print( "   \(key.str) -> \(tag.getRichText())" )
                }
                print("")
            }


            DebugButton( label: "Print Macro Table" ) {
                
                print("Macro Table:")
                for mfr in model.db.indexFile.mfileTable {
                    let caption = mfr.caption ?? "-caption-"
                    print( "   \(mfr.modSym)  \(caption)" )
                }
                print("")
            }
        }
    }
}
