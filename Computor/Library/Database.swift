//
//  Database.swift
//  Computor
//
//  Created by Barry Hall on 2025-06-07.
//
import SwiftUI


class IndexFile: Codable {
    
    /// Only one of these tables per app
    /// Contains a record of each macro library file
    
    var stateTable: [DocumentFileRec] = []
    var mfileTable: [ModuleFileRec] = []
}


let modZeroSym = "mod0"


// ********************************************************* //


class Database {
    
    var indexFile: IndexFile = IndexFile()
}


extension Database {
    
    func getModuleFileRec( sym: String ) -> ModuleFileRec? {
        indexFile.mfileTable.first( where: { $0.modSym == sym } )
    }
    
    func getModuleFileRec( id: UUID ) -> ModuleFileRec? {
        indexFile.mfileTable.first( where: { $0.id == id } )
    }
    
    
    // *** File system paths ***
    
    static func documentDirectoryURL() -> URL {
        
        try! FileManager.default.url(for: .documentDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: false)
    }

    private static func indexFileURL() -> URL {
        Database.documentDirectoryURL().appendingPathComponent("computor.index")
    }
    
    static func moduleDirectoryURL() -> URL {
        Database.documentDirectoryURL().appendingPathComponent("Module")
    }

    // ***************
    
    
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
        
        indexFile = iFile
        
#if DEBUG
        print( "Index File \(iFile.stateTable.count) State Records, \(iFile.mfileTable.count) MacroModules" )
        for mfr in indexFile.mfileTable {
            print( "   Index mfr: \(mfr.modSym) - \(mfr.id.uuidString)" )
        }
#endif
    }
    
    
    
    func saveIndex() {
        
        /// ** Save Index **
        
        do {
            let store = IndexStore( indexFile )
            let data = try JSONEncoder().encode(store)
            let outfile = Self.indexFileURL()
            try data.write(to: outfile)
            
            print( "saveIndexFileTask: wrote out IndexFile")
        }
        catch {
            print( "saveIndexFile: error: \(error.localizedDescription)")
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

    
    func syncModules() {
        
        /// ** Sync Modules **
        /// Make Index file consistent with actual module files present
        
        print( "Sync Modules:" )
        
        let modDir = Database.moduleDirectoryURL()
        
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
        for mfr in indexFile.mfileTable {
            
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
        
        print( "   Number of matched files(\(numMatched)), remaining valid(\(validModFiles.count)), index entries(\(indexFile.mfileTable.count))" )
        
        // Eliminate index file entries where the file is missing
        indexFile.mfileTable.removeAll( where: { missingFiles.contains( $0.id ) } )
        
        print( "   Remaining index entries after removing missing files(\(indexFile.mfileTable.count))")
        
        // Add index entries for remaining valid files
        for (modName, modUUID) in validModFiles {
            
            print("   Adding ModFileRec to index for: \(modName) - \(modUUID.uuidString)")
            
            guard let _ = addExistingModuleFile( symbol: modName, uuid: modUUID) else {
                // assert(false)
                print( "   Mod: \(modName) - \(modUUID) conflict with existing module with same name" )
                return
            }
        }
        
        if !validModFiles.isEmpty || !missingFiles.isEmpty {
            // Write out index file since we added or removed entries to it
            saveIndex()
        }
    }

    
    func getModZero() -> ModuleFileRec {
        
        /// ** Create the Zero Module **
        
        if let mod0 = getModuleFileRec( sym: modZeroSym ) {
            
            // Module zero already exists
            print( "createModZero: Already exists" )
            return mod0
        }
        
        guard let mod0 = createNewModule( symbol: modZeroSym) else {
            print( "createModZero: Failed to create Mod zero" )
            assert(false)
        }
        
        print( "createModZero: Created" )
        return mod0
    }
    
    // **********

    
    func loadModule( _ mfr: ModuleFileRec ) -> ModuleFile {
        
        // TODO: Should we eliminate this func
        
        /// ** Load Module **
        return mfr.loadModule()
    }

    
    func saveModule( _ mfr: ModuleFileRec ) {
        
        // TODO: Should we eliminate this func

        /// ** Save Module **
        mfr.saveModule()
    }

    
    func loadLibrary() {
        
        /// ** Load Library **
        
        createModuleDirectory()
        loadIndex()
        syncModules()
        
        // Create Module zero if it doesn't exist and load it
        let mod0 = getModZero()
        let _ = loadModule(mod0)
    }
    

    // *****************
    // Library Functions
    
    func createNewModule( symbol: String ) -> ModuleFileRec? {
        
        /// ** Create New Module File **
        ///     Create a new module file with unique symbol and a new UUID
        
        if let _ = getModuleFileRec(sym: symbol) {
            // Already exists with this symbol
            return nil
        }
        
        let mfr = ModuleFileRec( sym: symbol)
        indexFile.mfileTable.append(mfr)
        
        let modFile = ModuleFile(mfr)
        mfr.mfile = modFile
        
        return mfr
    }

    
    func addExistingModuleFile( symbol: String, uuid: UUID ) -> ModuleFileRec? {
        
        /// ** Add Existing Module File **
        ///     Create a new module file with unique symbol and a new UUID
        
        if let _ = getModuleFileRec(sym: symbol) {
            // Already exists with this symbol
            return nil
        }
            
        let mfr = ModuleFileRec( sym: symbol, uuid: uuid )
        indexFile.mfileTable.append(mfr)
        return mfr
    }
    
    
    func setSymbol( _ mfr: ModuleFileRec, to newSym: String ) {
        assert( newSym.count <= 6 && newSym.count > 0 )
        
        
    }
    
    
    func deleteModule( _ mfr: ModuleFileRec ) {
        
        /// ** Delete Module **
        
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
        
        // Remove this module from the index
        indexFile.mfileTable.removeAll( where: { $0.modSym == mfr.modSym })
    }
    
    
    func setModuleSymbolandCaption( _ mfr: ModuleFileRec, newSym: String, newCaption: String? = nil ) {
        
        /// ** Set Module Symbol and Caption **
        
        // Load the module file
        let mod = loadModule(mfr)
        
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
        
        saveModule(mfr)
        saveIndex()
    }
    
    
    func getRemoteSymbolTag( for tag: SymbolTag, to remMod: ModuleFileRec, from local: ModuleFileRec? = nil ) -> SymbolTag {
        
        let localMod: ModuleFileRec = local ?? getModZero()
        
        if remMod == localMod {
            
            // Reference is local - no change
            return tag
        }
        
        // Add this remote id to the local module, create a remote tag
        let modIndex = localMod.getRemoteModuleIndex( for: remMod )
        let remSym = SymbolTag( tag, mod: modIndex )
        return remSym
    }
    
    
    func getMacro( for tag: SymbolTag, localMod: ModuleFileRec ) -> MacroRec? {
        
        if tag.isLocalTag {
            
            // Lookup tag in local module provided
            return localMod.getMacro(tag)
        }
        
        // remTag is local to the remote Mod
        let remTag = tag.localTag
        let modIndex = tag.mod
        
        // Obtain the uuid of the remote module
        if let remModId = localMod.remoteModuleRef( modIndex ) {
            
            // and lookup the module rec
            if let mfrRem = getModuleFileRec(id: remModId) {
                
                // Look for the macro here
                return mfrRem.getMacro(remTag)
            }
        }
        
        // Bad reference
        return nil
    }
}

