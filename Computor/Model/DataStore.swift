//
//  DataStore.swift
//  Computor
//
//  Created by Barry Hall on 2025-05-20.
//
import SwiftUI


extension CalculatorModel {
    
    // *** File system paths ***
    
    static func documentDirectoryURL() -> URL {
        
        try! FileManager.default.url(for: .documentDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: false)
    }
    
    private static func configFileURL() -> URL {
        documentDirectoryURL().appendingPathComponent("computor.config")
    }
    
    private static func stateFileURL() -> URL {
        documentDirectoryURL().appendingPathComponent("computor.state")
    }
    
    // ***************


    func loadLibrary() {
        
        /// ** Load Library **
        
        do {
            db.createModuleDirectory()
            
            db.loadIndex()
            
            db.syncModules()
            
            // Create Module zero if it doesn't exist and load it
            let mod0 = db.createModZero()
            let mf = db.loadModule(mod0)
            
            // Set aux display view to mod zero
            self.aux.macroMod = mf
            print("Display aux.macroMod = \(mf.modSym) - \(mf.id.uuidString)")

            try loadState()
        }
        catch {
            print( "Library load error: \(error.localizedDescription)" )
        }
    }


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

    
    func loadState() throws {
        
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
    
    
    func saveConfiguration() {
        
        /// ** saveConfiguration **
        
        do {
            let store = Database.ModuleStore( aux.macroMod )
            let data = try JSONEncoder().encode(store)
            let outfile = Database.moduleDirectoryURL().appendingPathComponent( aux.macroMod.filename )
            try data.write(to: outfile)
            
            print( "saveConfigTask: wrote out: \(aux.macroMod.filename)")
        }
        catch {
            print( "saveConfiguration: error: \(error.localizedDescription)")
        }
    }
    
    
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

    
    func saveState() throws {
        /// Save calculator state when app terminates
        
        let store = DataStore( state, UserUnitData.uud, kstate.keyMap )
        let data = try JSONEncoder().encode(store)
        let outfile = Self.stateFileURL()
        try data.write(to: outfile)
    }

}


/// ** Utility File Functions **


func listFiles( inDirectory path: String, withPrefix pattern: String ) -> [String] {
    
    /// ** List Files in Path **
    
    let fileManager = FileManager.default
    
    do {
        let contents = try fileManager.contentsOfDirectory( atPath: path)
        let filteredFiles = contents.filter { $0.hasPrefix(pattern) }
        return filteredFiles
    }
    catch {
        print("Error listing path \(path) Error: \(error) - return []")
        return []
    }
}


func deleteFile( fileName: String, inDirectory directoryURL: URL) {
    
    let fileManager = FileManager.default
    let fileURL = directoryURL.appendingPathComponent(fileName)
    
    do {
        try fileManager.removeItem(at: fileURL)
        
#if DEBUG
        print("File '\(fileName)' successfully deleted from '\(directoryURL.lastPathComponent)' directory.")
#endif
    }
    catch {
        print("Error deleting file '\(fileName)': \(error.localizedDescription)")
    }
}


func deleteAllFiles( in directoryURL: URL) {
    
    let fileManager = FileManager.default
    
    do {
        // Get the contents of the directory
        let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        // Iterate through the files and remove each one
        for fileURL in fileURLs {
            try fileManager.removeItem(at: fileURL)
        }
        
#if DEBUG
        print("Successfully deleted all files in: \(directoryURL.lastPathComponent)")
#endif
    }
    catch {
        print("Error deleting files in directory: \(error)")
    }
}


func renameFile( originalURL: URL, newName: String) {
    
    let fileManager = FileManager.default
    
    // Get the directory of the original file
    let directoryURL = originalURL.deletingLastPathComponent()
    
    // Create the new URL with the desired new name
    let newURL = directoryURL.appendingPathComponent(newName)
    
    do {
        try fileManager.moveItem(at: originalURL, to: newURL)
        
        print("File successfully renamed from \(originalURL.lastPathComponent) to \(newURL.lastPathComponent)")
    }
    catch {
        print("Error renaming file: \(error.localizedDescription)")
    }
}
