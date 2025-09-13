//
//  DataStore.swift
//  Computor
//
//  Created by Barry Hall on 2025-05-20.
//
import SwiftUI


extension CalculatorModel {
    
    // *** File system paths ***
    
    private static func documentDirectoryURL() -> URL {
        
        try! FileManager.default.url(for: .documentDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: false)
    }
    
    private static func indexFileURL() -> URL {
        documentDirectoryURL().appendingPathComponent("computor.index")
    }
    
    private static func configFileURL() -> URL {
        documentDirectoryURL().appendingPathComponent("computor.config")
    }
    
    private static func stateFileURL() -> URL {
        documentDirectoryURL().appendingPathComponent("computor.state")
    }
    
    static func moduleDirectoryURL() -> URL {
        documentDirectoryURL().appendingPathComponent("Module")
    }
    
    
    func createModuleDirectory() {
        
        /// ** Create Module Directory **
        /// Create the 'Module' subdir under the document directory
        
        let modDirURL = Self.moduleDirectoryURL()
        
        do {
            try FileManager.default.createDirectory( at: modDirURL, withIntermediateDirectories: false, attributes: nil)
            
            print("Directory created successfully at: \(modDirURL.path)")
        }
        catch CocoaError.fileWriteFileExists {
            print( "Module directory already exists - no problem" )
        }
        catch {
            print("Error creating directory: \(error.localizedDescription)")
            assert(false)
        }
    }
    
    // ***************
    

    struct IndexStore : Codable {
        
        /// ** IndexStore **
        /// List of other data files, macro and state files
        ///
        
        var indexFile: IndexFile
        
        init( _ iFile: IndexFile = IndexFile() ) {
            self.indexFile = iFile
        }
    }

    
    func loadIndex() {
        
        /// ** Load Index **
        
        var iFile: IndexFile
        
        do {
            // Try to load file Computor.Index
            let fileURL = Self.indexFileURL()
            let data    = try Data( contentsOf: fileURL)
            let index   = try JSONDecoder().decode( IndexStore.self, from: data)
            iFile = index.indexFile
            
            print( "Load Index Successful" )
        }
        catch {
            // File not found - Return an empty Index
            iFile = IndexFile()
            
            print( "Index file not found - using empty file" )
        }
        
        self.db.indexFile = iFile
        
#if DEBUG
        print( "Index File \(iFile.stateTable.count) State Records, \(iFile.mfileTable.count) MacroModules" )
        for mfr in db.indexFile.mfileTable {
            print( "   Index mfr: \(mfr.modSym) - \(mfr.id.uuidString)" )
        }
#endif
    }
    
    
    
    func saveIndex() {
        
        /// ** Save Index **
        
        do {
            let store = IndexStore( db.indexFile )
            let data = try JSONEncoder().encode(store)
            let outfile = Self.indexFileURL()
            try data.write(to: outfile)
            
            print( "saveIndexFileTask: wrote out IndexFile")
        }
        catch {
            print( "saveIndexFile: error: \(error.localizedDescription)")
        }
    }

    // ***************
    
    
    func syncModules() {
        
        /// ** Sync Modules **
        /// Make Index file consistent with actual module files present
        
        print( "Sync Modules:" )
        
        let modDir = Self.moduleDirectoryURL()
        
        let modFilenameList = listFiles( inDirectory: modDir.path(), withPrefix: "Module.")
        
        print("#1 mod filename list:")
        for fn in modFilenameList {
            print( "   found: \(fn)" )
        }
        print("")

        var validModFiles: [(String, UUID)] = modFilenameList.compactMap { fname in splitModFilename(fname) }
        
        var missingFiles: [UUID] = []
        
#if DEBUG
        print("#2 Valid files found:")
        for (name, uuid) in validModFiles {
            print( "   \(name) - \(uuid.uuidString)" )
        }
        print("")
#endif
        
        var numMatched = 0
        
        // For each record in the index file
        for mfr in db.indexFile.mfileTable {
            
            if let (modName, modUUID) = validModFiles.first( where: { (name, uuid) in uuid == mfr.id } ) {
                
                // The file exists
                
                if modName != mfr.modSym {
                    // Should not happen - correct index
                    assert(false)
                    mfr.modSym = modName
                }
                
                print( "   Mod file match: \(modName) - \(modUUID.uuidString)" )
                numMatched += 1
                
                validModFiles.removeAll( where: { (name, uuid) in uuid == mfr.id } )
            }
            else {
                // No file matching this index entry
                missingFiles.append(mfr.id)
                
                print( "   Missing mod file for index entry: \(mfr.modSym) - \(mfr.id.uuidString)")
            }
        }
        
        print( "   Number of matched files(\(numMatched)), remaining valid(\(validModFiles.count)), index entries(\(db.indexFile.mfileTable.count))" )
        
        // Eliminate index file entries where the file is missing
        db.indexFile.mfileTable.removeAll( where: { missingFiles.contains( $0.id ) } )
        
        print( "   Remaining index entries after removing missing files(\(db.indexFile.mfileTable.count))")
        
        // Add index entries for remaining valid files
        for (modName, modUUID) in validModFiles {
            
            print("   Adding ModFileRec to index for: \(modName) - \(modUUID.uuidString)")
            
            guard let _ = db.addExistingMacroFile( symbol: modName, uuid: modUUID) else {
                assert(false)
                print( "   Mod: \(modName) - \(modUUID) conflict with existing module with same name" )
            }
        }
        
        if !validModFiles.isEmpty || !missingFiles.isEmpty {
            // Write out index file since we added or removed entries to it
            saveIndex()
        }
    }

    
    func createModZero() -> MacroFileRec {
        
        /// ** Create the Zero Module **
        
        if let mod0 = db.getMacroFileRec( sym: modZeroSym ) {
            
            // Module zero already exists
            print( "createModZero: Already exists" )
            return mod0
        }
        
        guard let mod0 = db.createNewMacroFile( symbol: modZeroSym) else {
            print( "createModZero: Failed to create Mod zero" )
            assert(false)
        }
        
        print( "createModZero: Created" )
        return mod0
    }
    
    
    func loadModule( _ mfr: MacroFileRec ) -> ModuleFile {
        
        /// ** Load Module **
        
        if let mf = mfr.mfile {
            // Module already loaded
            print( "loadModule: \(mfr.modSym) already loaded" )
            return mf
        }
        
        do {
            let fileURL = Self.moduleDirectoryURL().appendingPathComponent( mfr.filename )
            let data = try Data( contentsOf: fileURL)
            let store = try JSONDecoder().decode(ModuleStore.self, from: data)
            let mod = store.modFile
            
            print( "loadModule: \(mfr.modSym) - \(mfr.id.uuidString) Loaded" )
            
            // Successful load
            mfr.mfile = mod
            return mod
        }
        catch {
            // Missing file or bad file
            
            print( "Creating Mod file for index: \(mfr.modSym) - \(mfr.id.uuidString)")
            
            // Create new module file for mfr rec and save it
            let mod = ModuleFile(mfr)
            mfr.mfile = mod
            saveModule(mfr)
            return mod
        }
    }


    func loadLibrary() {
        
        /// ** Load Library **
        
        do {
            createModuleDirectory()
            
            loadIndex()
            
            syncModules()
            
            // Create Module zero if it doesn't exist and load it
            let mod0 = createModZero()
            let mf = loadModule(mod0)
            
            // Set aux display view to mod zero
            self.aux.macroMod = mf
            print("Display aux.macroMod = \(mf.modSym) - \(mf.id.uuidString)")

            try loadState()
        }
        catch {
            print( "Library load error: \(error.localizedDescription)" )
        }
    }
    
    
    struct ModuleStore : Codable {
        
        /// ModuleStore
        
        var modFile: ModuleFile
        
        init( _ mFile: ModuleFile = ModuleFile() ) {
            self.modFile = mFile
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
    
    
    func splitModFilename( _ fname: String ) -> ( String, UUID )? {
        
        /// Break down a module filename of form 'Module.modName.UUID'
        
        if !fname.hasPrefix("Module.") {
            return nil
        }
        
        let parts = fname.split( separator: ".")
        
        if parts.count < 3 || parts[1].count > 6 {
            return nil
        }
        
        if let uuid = UUID( uuidString: String(parts[2]) ) {
            return (String(parts[1]), uuid)
        }
        
        return nil
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
    
    
    func saveConfigTask() throws {
        /// Save configuration immediately after a change
        /// Don't wait for app termination
        
        let store = ModuleStore( aux.macroMod )
        let data = try JSONEncoder().encode(store)
        let outfile = Self.moduleDirectoryURL().appendingPathComponent( aux.macroMod.filename )
        try data.write(to: outfile)

        print( "saveConfigTask: wrote out: \(aux.macroMod.filename)")
    }
    
    
    func saveConfiguration() {
        
        /// ** saveConfiguration **
        
        do {
            try saveConfigTask()
        }
        catch {
            print( "saveConfiguration: error: \(error.localizedDescription)")
        }
    }

    
    func saveModule( _ mfr: MacroFileRec ) {
        
        if let mod = mfr.mfile {
            
            // Mod file is loaded
            do {
                let store = ModuleStore( mod )
                let data = try JSONEncoder().encode(store)
                let outfile = Self.moduleDirectoryURL().appendingPathComponent( mod.filename )
                try data.write(to: outfile)
                
                print( "saveModule: wrote out: \(mod.filename)")
            }
            catch {
                print( "saveModule: file: \(mod.filename) error: \(error.localizedDescription)")
            }
        }
    }
    
    
    func deleteModule( _ mfr: MacroFileRec ) {
        
        // Delete the Mod file associated with this mfr rec if it exists
        if let mod = mfr.mfile {
            
            // Mod file is loaded
            let modDirURL = Self.moduleDirectoryURL()
            deleteFile( fileName: mod.filename, inDirectory: modDirURL )
            mfr.mfile = nil
        }
        else {
            
            // Mod file is not loaded - delete it anyway
            let modDirURL = Self.moduleDirectoryURL()
            deleteFile( fileName: mfr.filename, inDirectory: modDirURL )
        }
    }
    
    
    func setModuleSymbolandCaption( _ mfr: MacroFileRec, newSym: String, newCaption: String? = nil ) {
        
        // Load the module file
        let mod = loadModule(mfr)
        
        let symChanged = newSym != mfr.modSym
        
        // Original mod URL
        let modURL = Self.moduleDirectoryURL().appendingPathComponent( mod.filename )
        
        if symChanged {
            
            mfr.modSym = newSym
            mod.modSym = newSym
            
            renameFile( originalURL: modURL, newName: mod.filename)
        }
        
        mfr.caption = newCaption
        mod.caption = newCaption
        
        saveModule(mfr)
        saveIndex()
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
