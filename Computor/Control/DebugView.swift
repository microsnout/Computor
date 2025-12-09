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
        
        NavigationStack {
            
            VStack {
                
                DebugButton( label: "Clear Key Assignments") {
                    model.kstate.keyMap.fnRow.removeAll()
                }
                
                DebugButton( label: "Print Key Assignments") {
                    
                    let mod0 = model.db.getModZero()
                    
                    print( "Key Assignments:" )
                    
                    for (kc, tag) in model.kstate.keyMap.fnRow {
                        
                        print( "   kc: \(kc.str)   tag: \(tag)")
                        
                        if let (mr, mfr) = model.db.getMacro(for: tag, localMod: mod0) {
                            
                            print( "      Macro: \(mr.symTag.getRichText()) in Mod: \(mfr.name)" )
                        }
                        
                    }
                }
                
                DebugButton( label: "Delete All Macros") {
                    model.kstate.keyMap.fnRow.removeAll()
                    model.aux.macroRec = nil
                    model.aux.macroMod = model.db.getModZero()
                    model.db.deleteAllMacros()
                }
                
                DebugButton( label: "Print Macro Table" ) {
                    
                    let mod = model.aux.macroMod
                        
                    print( "Mod: \(mod.name):" )
                    
                    print( "Symlist: \(String( describing: mod.symList))" )
                    
                    for mr in mod.macroList {
                        
                        print( "    \(mr.symTag.getRichText())" )
                    }
                        
                }
                
                DebugButton( label: "Delete ALL Module files") {
                    
                    
                    for mfr in model.db.modList {
                        model.db.deleteModule(mfr)
                    }
                    
                    model.kstate.keyMap.fnRow.removeAll()
                    model.aux.macroRec = nil
                    
                    let mod0 = model.db.getModZero()
                    let _ = model.db.loadModule(mod0)
                    
                    model.db.modTable.saveTable()
                    
                    let modDir = model.db.modTable.objectDirectoryURL
                    deleteAllFiles(in: modDir)
                }
                
                
                DebugButton( label: "Print Key Maps" ) {
                    
                    print("Key Map:")
                    for (key, tag) in model.kstate.keyMap.fnRow {
                        print( "   \(key.str) -> \(tag)" )
                    }
                    print("")
                }
                
                
                DebugButton( label: "Print Module Table" ) {
                    
                    let n = model.db.modTable.objTable.count
                    
                    print("Macro Table: \(n) entries")
                    
                    for mfr in model.db.modTable.objTable {
                        
                        let mf = mfr.loadModule()
                        
                        let idMatch = mfr.id == mf.id
                        
                        print( "   \(mfr.name) - \(mfr.id.uuidString)  MF: \(mf.name) Id match: \(idMatch)" )
                    }
                    print("")
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SectionHeaderText( text: "Debug Functions" )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .padding()
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("ControlBack"))
        .scrollContentBackground(.hidden)
    }
}
