//
//  DataStore.swift
//  Computor
//
//  Created by Barry Hall on 2025-05-20.
//
import SwiftUI


extension CalculatorModel {
    

    struct DataStore : Codable {
        var state:    CalcState
        
        var unitData: UserUnitData
        
        var keyMap: KeyMapRec

        init( _ state: CalcState = CalcState(), _ uud: UserUnitData = UserUnitData(), _ keyM: KeyMapRec = KeyMapRec() ) {
            self.state = state
            self.unitData = uud
            self.keyMap   = keyM
        }
    }
    
    
    static func documentDirectoryURL() -> URL {
        
        try! FileManager.default.url(for: .documentDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: false)
    }
    
    private static func stateFileURL() -> URL {
        documentDirectoryURL().appendingPathComponent("computor.state")
    }

    func loadState() {
        
        do {
            let fileURL = Self.stateFileURL()
            let data  = try Data( contentsOf: fileURL)
            let store = try JSONDecoder().decode(DataStore.self, from: data)
            
            // Update the @Published property here
            UserUnitData.uud = store.unitData
            self.state = store.state
            self.kstate.keyMap = store.keyMap
            
            UnitDef.reIndexUserUnits()
            TypeDef.reIndexUserTypes()
        }
        catch {
            print( "State load error: \(error.localizedDescription)" )
        }
    }

    
    func saveState() throws {
        /// Save calculator state when app terminates
        
        let store = DataStore( state, UserUnitData.uud, kstate.keyMap )
        let data = try JSONEncoder().encode(store)
        let outfile = Self.stateFileURL()
        try data.write(to: outfile)
    }
    
    // ***

    
    func saveConfiguration() {
        
        /// ** saveConfiguration **
        
        do {
            let mod = aux.macroMod.loadModule()
            let store = ModuleStore( mod )
            let data = try JSONEncoder().encode(store)
            let outfile = Database.moduleDirectoryURL().appendingPathComponent( aux.macroMod.filename )
            try data.write(to: outfile)
            
            print( "saveConfigTask: wrote out: \(aux.macroMod.filename)")
        }
        catch {
            print( "saveConfiguration: error: \(error.localizedDescription)")
        }
    }
    
    
    // Lib Functions
    
    func deleteModule( _ mfr: MacroFileRec ) {
        
        // Delete the Mod file associated with this mfr rec if it exists
        if let mod = mfr.mfile {
            
            // Mod file is loaded
            let modDirURL = Database.moduleDirectoryURL()
            deleteFile( fileName: mod.filename, inDirectory: modDirURL )
            mfr.mfile = nil
        }
        else {
            
            // Mod file is not loaded - delete it anyway
            let modDirURL = Database.moduleDirectoryURL()
            deleteFile( fileName: mfr.filename, inDirectory: modDirURL )
        }
    }
    
    
    func setModuleSymbolandCaption( _ mfr: MacroFileRec, newSym: String, newCaption: String? = nil ) {
        
        // Load the module file
        let mod = db.loadModule(mfr)
        
        let symChanged = newSym != mfr.modSym
        
        // Original mod URL
        let modURL = Database.moduleDirectoryURL().appendingPathComponent( mod.filename )
        
        if symChanged {
            
            mfr.modSym = newSym
            mod.modSym = newSym
            
            renameFile( originalURL: modURL, newName: mod.filename)
        }
        
        mfr.caption = newCaption
        mod.caption = newCaption
        
        db.saveModule(mfr)
        db.saveIndex()
    }

}

