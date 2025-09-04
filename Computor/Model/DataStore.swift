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
    
    
    func loadIndex() async {
        
        /// ** Load Index File **
        
        let task = Task<IndexStore, Error> {
            let fileURL = Self.indexFileURL()
            let data    = try Data( contentsOf: fileURL)
            let index   = try JSONDecoder().decode( IndexStore.self, from: data)
            return index
        }
        
        var iFile: ComputorIndexFile
        
        do {
            // Try to load file Computor.Index
            let store = try await task.value
            iFile = store.indexFile
            
            print( "Load Index Successful" )
        }
        catch {
            // File not found - Return an empty Index
            iFile = ComputorIndexFile()
            
            print( "Index file not found - using empty file" )
        }
        
        Task { @MainActor in
            self.libRec.indexFile = iFile
            
            print( "Index File \(iFile.stateTable.count) State Records, \(iFile.macroTable.count) MacroModules" )
        }
    }
    
    
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

    
    func syncModules() {
        
        /// ** Sync Modules **
        /// Make Index file consistent with actual module files present
        
        print( "Sync Modules:" )
        
        let modDir = Self.moduleDirectoryURL()
        
        let modFilenameList = listFiles( inDirectory: modDir.path(), withPrefix: "Module.")
        
        var validModFiles: [(String, UUID)] = modFilenameList.compactMap { fname in splitModFilename(fname) }
        
        var missingFiles: [UUID] = []
        
        // For each record in the index file
        for mfr in libRec.indexFile.macroTable {
            
            if let (modName, modUUID) = validModFiles.first( where: { (name, uuid) in uuid == mfr.id } ) {
                
                // The file exists
                
                if modName != mfr.symbol {
                    // Should not happen - correct index
                    assert(false)
                    mfr.symbol = modName
                }
                
                print( "   Module: \(modName) - \(modUUID.uuidString)" )
                
                validModFiles.removeAll( where: { (name, uuid) in uuid == mfr.id } )
            }
            else {
                // No file matching this index entry
                missingFiles.append(mfr.id)
            }
        }
        
        // Eliminate index file entries where the file is missing
        libRec.indexFile.macroTable.removeAll( where: { missingFiles.contains( $0.id ) } )
        
        // Add index entries for remaining valid files
        for (modName, modUUID) in validModFiles {
            
            print("   Adding ModFileRec for: \(modName)")
            
            guard let _ = libRec.addExistingMacroFile( symbol: modName, uuid: modUUID) else {
                assert(false)
                print( "   Mod: \(modName) - \(modUUID) conflict with existing module with same name" )
            }
        }
    }

    
    func createModZero() -> MacroFileRec {
        
        /// ** Create the Zero Module **
        
        if let mod0 = libRec.getMacroFileRec( sym: modZeroSym ) {
            
            // Module zero already exists
            print( "createModZero: Already exists" )
            return mod0
        }
        
        guard let mod0 = libRec.createNewMacroFile( symbol: modZeroSym) else {
            print( "createModZero: Failed to create Mod zero" )
            assert(false)
        }
        
        print( "createModZero: Created" )
        return mod0
    }

    
    typealias LoadContinuationClosure = ( ModuleFile ) -> Void
    
    func loadModule( _ mfr: MacroFileRec, lcc: @escaping LoadContinuationClosure ) async {
        
        /// ** Load Module **
        
        if let mf = mfr.mfile {
            // Module already loaded
            print( "loadModule: \(mfr.symbol) already loaded" )
            lcc(mf)
            return
        }
        
        let task = Task<ModuleStore, Error> {
            
            let fileURL = Self.moduleDirectoryURL().appendingPathComponent( mfr.filename )
            
            guard let data = try? Data( contentsOf: fileURL) else {
                
                print("LoadModule - Failed: return empty ModuleStore")
                return ModuleStore()
            }
            
            let modS = try JSONDecoder().decode(ModuleStore.self, from: data)
            return modS
        }
        
        var store = ModuleStore()

        do {
            store = try await task.value
        }
        catch {
            print("loadModule - JSON Decode Failed:" )
            print("   symbol: \(mfr.symbol)")
            print("       id: \(mfr.id)")
            print("    Error: \(error)")
            
            let md = ModuleFile(mfr)
            store = ModuleStore(md)
        }
        
        mfr.mfile = store.modFile
        print( "loadModule: sym:\(mfr.symbol) Loaded" )
        print( "loadModule - ModuleFile: \(mfr.mfile?.modSym ?? "-")" )
        
        Task { @MainActor in
            lcc(store.modFile)
        }
    }


    func loadLibrary() async {
        
        do {
            createModuleDirectory()
            
            await loadIndex()
            
            syncModules()
            
            // Create Module zero if it doesn't exist and load it
            let mod0 = createModZero()
            
            await loadModule(mod0) { mf in
                self.aux.macroMod = mf
                print("Assign aux.macroMod = \(mf.modSym)")
            }

            try await loadState()
        }
        catch {
            print( "Library load error: \(error.localizedDescription)" )
        }
    }
    
    
    struct IndexStore : Codable {
        /// IndexStore
        /// List of other data files, macro and state files
        ///
        
        var indexFile: ComputorIndexFile
        
        init( _ iFile: ComputorIndexFile = ComputorIndexFile() ) {
            self.indexFile = iFile
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

    
    func loadState() async throws {
        
        let task = Task<DataStore, Error> {
            let fileURL = Self.stateFileURL()
            
            guard let data = try? Data( contentsOf: fileURL) else {
                return DataStore()
            }
            
            let state = try JSONDecoder().decode(DataStore.self, from: data)
            return state
        }
        
        let store = try await task.value

        Task { @MainActor in
            // Update the @Published property here
            UserUnitData.uud = store.unitData
            self.state = store.state
            self.kstate.keyMap = store.keyMap

            UnitDef.reIndexUserUnits()
            TypeDef.reIndexUserTypes()
        }
    }
    
    func saveConfigTask() async throws {
        /// Save configuration immediately after a change
        /// Don't wait for app termination
        
        let task = Task {
            let store = ModuleStore( aux.macroMod )
            let data = try JSONEncoder().encode(store)
            let outfile = Self.moduleDirectoryURL().appendingPathComponent( aux.macroMod.filename )
            try data.write(to: outfile)
        }
        _ = try await task.value
        
        print( "saveConfigTask: wrote out: \(aux.macroMod.filename)")
    }
    
    func saveConfiguration() {
        
        Task {
            do {
                try await saveConfigTask()
            }
            catch {
                print( "saveConfiguration: error: \(error.localizedDescription)")
                
//                fatalError(error.localizedDescription)
            }
        }
    }

    func saveState() async throws {
        /// Save calculator state when app terminates
        
        let task = Task {
            let store = DataStore( state, UserUnitData.uud, kstate.keyMap )
            let data = try JSONEncoder().encode(store)
            let outfile = Self.stateFileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }

}


/// ** Functions for Debug control sheet **

func deleteAllFiles(in directoryURL: URL) {
    let fileManager = FileManager.default
    
    do {
        // Get the contents of the directory
        let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        // Iterate through the files and remove each one
        for fileURL in fileURLs {
            try fileManager.removeItem(at: fileURL)
        }
        print("Successfully deleted all files in: \(directoryURL.lastPathComponent)")
    }
    catch {
        print("Error deleting files in directory: \(error)")
    }
}
