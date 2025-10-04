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
    
    var dFileTable: [DocumentRec] = []
    var mfileTable: [ModuleFileRec] = []
}


let modZeroSym = "mod0"
let docZeroSym = "doc0"


// ********************************************************* //


class Database {
    
    var indexFile: IndexFile = IndexFile()
    
    var docTable = ObjectTable<DocumentRec>( tableName: "Computor", objZeroName: "doc0" )
}


extension Database {
    
    func getModuleFileRec( sym: String ) -> ModuleFileRec? {
        indexFile.mfileTable.first( where: { $0.name == sym } )
    }
    
    func getModuleFileRec( id: UUID ) -> ModuleFileRec? {
        indexFile.mfileTable.first( where: { $0.id == id } )
    }
    
    func getDocumentFileRec( name: String ) -> DocumentRec? {
        docTable.getObjectFileRec(name)
    }
    
    func getDocumentFileRec( id uuid: UUID ) -> DocumentRec? {
        docTable.getObjectFileRec(id: uuid)
    }
    
    func getDocZero() -> DocumentRec {
        docTable.getObjZero()
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
        print( "Index File \(iFile.dFileTable.count) State Records, \(iFile.mfileTable.count) MacroModules" )
        for mfr in indexFile.mfileTable {
            print( "   Index mfr: \(mfr.name) - \(mfr.id.uuidString)" )
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
        
        var validModFiles: [(String, UUID)] = modFilenameList.compactMap { fname in splitModFilename(fname) }
        
        var missingFiles: [UUID] = []
        
        var mod0IdList: [UUID] = validModFiles.compactMap( { (sym, uuid) in sym == modZeroSym ? uuid : nil } )
        
#if DEBUG
        print("#1 mod filename list:")
        for fn in modFilenameList {
            print( "   found: \(fn)" )
        }
        print("")
        
        print("#2 Valid files found:")
        for (name, uuid) in validModFiles {
            print( "   \(name) - \(uuid.uuidString)" )
        }
        print("")
        
        if mod0IdList.count > 1 {
            print("Multiple Mod0 files")
            for id in mod0IdList {
                print( "   mod0 - \(id.uuidString)" )
            }
        }
#endif
        
        var numMatched = 0
        
        var mfrMod0: ModuleFileRec? = nil
        
        // For each record in the index file
        for mfr in indexFile.mfileTable {
            
            if let (modName, modUUID) = validModFiles.first( where: { (name, uuid) in uuid == mfr.id } ) {
                
                // The file exists
                
                if modName != mfr.name {
                    // Should not happen - correct index
                    assert(false)
                    mfr.name = modName
                }
                
                print( "   Mod file match: \(modName) - \(modUUID.uuidString)" )
                numMatched += 1
                
                if modName == modZeroSym {
                    // Enforce only one mod0
                    assert( mfrMod0 == nil )
                    mfrMod0 = mfr
                    
                    // Remove the mod0 file id that matches Index
                    mod0IdList.removeAll(where: { $0 == mfr.id } )
                }
                
                validModFiles.removeAll( where: { (name, uuid) in uuid == mfr.id } )
            }
            else {
                // No file matching this index entry
                missingFiles.append(mfr.id)
                
                print( "   Missing mod file for index entry: \(mfr.name) - \(mfr.id.uuidString)")
            }
        }
        
        print( "   Number of matched files(\(numMatched)), remaining valid(\(validModFiles.count)), index entries(\(indexFile.mfileTable.count))" )
        
        // Eliminate index file entries where the file is missing
        indexFile.mfileTable.removeAll( where: { missingFiles.contains( $0.id ) } )
        
        print( "   Remaining index entries after removing missing files(\(indexFile.mfileTable.count))")
        
        // Add index entries for remaining valid files
        for (modName, modUUID) in validModFiles {
            
            if let _ = mfrMod0 {
                if modName == modZeroSym {
                    
                    // Don't add a 2nd Index for extra mod0 file
                    continue
                }
            }
            
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
        
        // Delete any extraneous mod0 files
        if mod0IdList.count > 0 {
            for uuid in mod0IdList {
                deleteFile( fileName: "Module.mod0.\(uuid.uuidString)", inDirectory: modDir )
            }
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
        
        print( "createModZero: Created mod0 - \(mod0.id.uuidString)" )
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
        
        docTable.loadObjectTable()
    }
    
    
    // *****************
    // Library Functions
    
    func createNewModule( symbol: String ) -> ModuleFileRec? {
        
        /// ** Create New Module File **
        ///     Create a new module file Index entry with unique symbol and a new UUID
        ///     Don't create a ModuleFile until needed
        
        if let _ = getModuleFileRec(sym: symbol) {
            // Already exists with this symbol
            print( "createNewModule: Attempt to create duplicat named mod: \(symbol)")
            assert(false)
            return nil
        }
        
        let mfr = ModuleFileRec( sym: symbol)
        
        // Add to Index and save
        indexFile.mfileTable.append(mfr)
        saveIndex()
        
        return mfr
    }
    
    
    func addExistingModuleFile( symbol: String, uuid: UUID ) -> ModuleFileRec? {
        
        /// ** Add Existing Module File **
        ///     Create a new module file with unique symbol and a new UUID
        
        if let _ = getModuleFileRec(sym: symbol) {
            // Already exists with this symbol
            return nil
        }
        
        // Create module file index entry
        let mfr = ModuleFileRec( sym: symbol, uuid: uuid )
        indexFile.mfileTable.append(mfr)
        
        let mf = mfr.loadModule()
        
        // Repair Index if needed
        if mf.name != mfr.name || mf.caption != mfr.caption {
            // assert(false)
            mfr.name = mf.name
            mfr.caption = mf.caption
            // TODO: set symList from module
            saveIndex()
        }
        
        return mfr
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
        indexFile.mfileTable.removeAll( where: { $0.name == mfr.name || $0.id == mfr.id })
        saveIndex()
    }
    
    
    func setModuleSymbolandCaption( _ mfr: ModuleFileRec, newSym: String, newCaption: String? = nil ) {
        
        /// ** Set Module Symbol and Caption **
        
        // Load the module file
        let mod = loadModule(mfr)
        
        let symChanged = newSym != mfr.name
        
        if symChanged {
            // Original mod URL
            let modURL = Database.moduleDirectoryURL().appendingPathComponent( mod.filename )
            
            
            mfr.name = newSym
            mod.name = newSym
            
            renameFile( originalURL: modURL, newName: mod.filename)
        }
        
        mfr.caption = newCaption
        mod.caption = newCaption
        
        saveModule(mfr)
        saveIndex()
    }
    
    
    func getRemoteSymbolTag( for tag: SymbolTag, to remMod: ModuleFileRec, from local: ModuleFileRec? = nil ) -> SymbolTag {
        
        /// ** Get Remote Symbol Tag **
        
        // if local module is not provided, use mod0
        let localMod: ModuleFileRec = local ?? getModZero()
        
        if remMod == localMod {
            
            // Reference is local - no change to tag
            return tag
        }
        
        // Add this remote id to the local module, create a remote tag
        let modIndex = localMod.getRemoteModuleIndex( for: remMod )
        
        // Create new version of sym tag with mod index added
        let remSym = SymbolTag( tag, mod: modIndex )
        return remSym
    }
    
    
    func getMacro( for tag: SymbolTag, localMod: ModuleFileRec ) -> (MacroRec, ModuleFileRec)? {
        
        /// ** Get Macro **
        
        if tag.isLocalTag {
            
            // Lookup tag in local module provided
            if let mr = localMod.getMacro(tag) {
                return (mr, localMod)
            }
            
            return nil
        }
        
        // remTag is local to the remote Mod
        let remTag = tag.localTag
        let modIndex = tag.mod
        
        // Obtain the uuid of the remote module
        if let remModId = localMod.remoteModuleRef( modIndex ) {
            
            // and lookup the module rec
            if let mfrRem = getModuleFileRec(id: remModId) {
                
                // Look for the macro here
                if let mr = mfrRem.getMacro(remTag) {
                    return (mr, mfrRem)
                }
            }
        }
        
        // Bad reference
        return nil
    }
    
    
    func deleteAllMacros() {
        
        /// ** Delete All Macros **  Debug use only
        
        for mfr in indexFile.mfileTable {
            
            if !mfr.isModZero {
                deleteModule(mfr)
            }
        }
        
        let mod0 = getModZero()
        mod0.symList = []
        saveIndex()
        
        let mf0 = mod0.loadModule()
        mf0.macroTable = []
        mf0.groupTable = [mod0.id]
        saveModule(mod0)
    }
    
    
    func deleteMacro( _ sTag: SymbolTag, from mfr: ModuleFileRec  ) {
        
        /// ** Delete Macro **
        
        // Remove this symbol from the cached symbol list
        mfr.symList.removeAll( where: { $0 == sTag } )
        saveIndex()
        
        mfr.deleteMacro(sTag)
    }
    
    
    func addMacro( _ mr: MacroRec, to mfc: ModuleFileRec ) {
        
        /// ** Add Macro **
        
        mfc.addMacro(mr)
        saveIndex()
    }
    
    
    func moveMacro( _ mr: MacroRec, from srcMod: ModuleFileRec, to dstMod: ModuleFileRec ) {
        
        // Move the existing macro rec
        addMacro( mr, to: dstMod )
        deleteMacro( mr.symTag, from: srcMod )
    }
    
    
    func copyMacro( _ mr: MacroRec, from srcMod: ModuleFileRec, to dstMod: ModuleFileRec ) {
        
        // Create a copy of the macro record
        let newMacro = mr.copy()
        addMacro( newMacro, to: dstMod )
    }
    
    
    // **************************
    // *** Document Functions ***
    
    
    func loadDocument( _ dfr: DocumentRec ) -> DocumentFile {
        
        // TODO: Should we eliminate this func
        
        /// ** Load Module **
        return dfr.loadDocument()
    }
    
    
    func saveDocument( _ dfr: DocumentRec ) {
        
        // TODO: Should we eliminate this func
        
        /// ** Save Module **
        dfr.saveDocument()
    }

    func deleteDocument( _ dfr: DocumentRec ) {
        
        /// ** Delete Document **
        docTable.deleteObject(dfr)
    }
    
    
    func createNewDocument( symbol: String, caption: String? = nil ) -> DocumentRec? {
        
        /// ** Create New Document File **
        ///     Create a new Document file Index entry with unique symbol and a new UUID
        ///     Don't create a DocumentFile until needed
        
        docTable.createNewObject(name: symbol, caption: caption)
    }
    
    
    func setDocumentSymbolandCaption( _ dfr: DocumentRec, newSym: String, newCaption: String? = nil ) {
        
        /// ** Set Document Symbol and Caption **
        
        docTable.setObjectNameAndCaption(dfr, newName: newSym, newCaption: newCaption)
    }
    
    func documentExists( _ name: String ) -> Bool {
        if let _ = docTable.getObjectFileRec(name) {
            return true
        }
        return false
    }
}
