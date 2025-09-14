//
//  Database.swift
//  Computor
//
//  Created by Barry Hall on 2025-06-07.
//
import SwiftUI


class MemoryRec: Codable, Identifiable, Hashable, Equatable {
    var tag:     SymbolTag
    var caption: String? = nil
    var tv:      TaggedValue
    
    var id: SymbolTag { tag }
    
    init( tag: SymbolTag, caption: String? = nil, tv: TaggedValue) {
        self.tag = tag
        self.caption = caption
        self.tv = tv
    }
    
    func hash( into hasher: inout Hasher) {
        hasher.combine(tag)
    }
    
    static func == ( lhs: MemoryRec, rhs: MemoryRec ) -> Bool {
        return lhs.tag == rhs.tag
    }
}


class MacroRec: Codable, Identifiable {
    var symTag:     SymbolTag
    var caption:    String? = nil
    var opSeq:      MacroOpSeq
    
    var id: SymbolTag { symTag }
    
    var isEmpty: Bool { symTag == SymbolTag(.null) && caption == nil && opSeq.isEmpty }
    
    init(tag symTag: SymbolTag = SymbolTag(.null) , caption: String? = nil, seq opSeq: MacroOpSeq = MacroOpSeq() ) {
        self.symTag = symTag
        self.caption = caption
        self.opSeq = opSeq
    }
}


struct KeyMapRec: Codable {
    
    var fnRow: [ KeyCode : SymbolTag ] = [:]
    
    func tagAssignment( _ kc: KeyCode ) -> SymbolTag? {
        fnRow[kc]
    }
    
    func keyAssignment( _ tag: SymbolTag ) -> KeyCode? {
        if tag.isNull {
            // Null tag, no key
            return nil
        }
        
        // Find the Fn key to which this sym is assigned if any
        if let index = fnRow.firstIndex( where: { $0.value == tag } ) {
            return fnRow[index].key
        }
        return nil
    }
    
    mutating func clearKeyAssignment( _ kc: KeyCode ) {
        fnRow.removeValue( forKey: kc)
    }
    
    mutating func assign( _ kc: KeyCode, tag: SymbolTag ) {
        // TODO: Eventually add UnRow for unit row keys
        fnRow[kc] = tag
    }
    
    // Could add unitRow here
}

// New code, not yet in service

typealias GroupId = Int


/// **  Module File **

class ModuleFile: Codable {
    
    /// One of these files per macro  module file
    
    // Unique ID for this module/file
    var id: UUID = UUID()
    
    // Short name of module - displayed as prefix to symbol
    var modSym: String = ""
    
    // Descriptive caption for this module
    var caption: String? = nil
    
    // Table of IDs of external referenced modules - array index is encoded in symbols
    var groupTable: [UUID] = []
    
    // List of macro definitions in this module - a macro must have a SymbolTag to be in this list, other fields optional
    var macroTable: [MacroRec] = []
    
    
    init( _ mfr: MacroFileRec ) {
        self.id = mfr.id
        self.modSym = mfr.modSym
        self.caption = mfr.caption
        self.groupTable = []
        self.macroTable = []
    }
    
    init() {
        self.id = UUID()
        self.modSym = ""
        self.caption = ""
        self.groupTable = []
        self.macroTable = []
    }
}

extension ModuleFile {
    
    var symStr: String { "{\(self.modSym)}" }
    
    var filename: String {
        "Module.\(modSym).\(id.uuidString)"
    }
}


struct ModuleStore : Codable {
    
    /// ModuleStore
    
    var modFile: ModuleFile
    
    init( _ mFile: ModuleFile = ModuleFile() ) {
        self.modFile = mFile
    }
}


// ********************************************************* //

/// ** Macro File Record **

final class MacroFileRec: Codable, Identifiable, Equatable {
    
    /// Description of one macro library file
    /// Contains a list of all symbols defined in file
    
    var id: UUID
    var modSym: String
    var caption: String? = nil
    var symList: [SymbolTag] = []
    
    // Not stored in Index file - nil if file not loaded
    var mfile: ModuleFile? = nil

    private enum CodingKeys: String, CodingKey {
        case id
        case modSym
        case caption
        case symList
        // Ignore mfile for Codable
    }
    
    init( sym: String ) {
        /// Constuction of a New Module file with newly created UUID
        self.id      = UUID()
        self.modSym  = sym
        self.caption = nil
        self.symList = []
        self.mfile   = nil
    }

    init( sym: String, uuid: UUID ) {
        /// Constuction of an existing Module file with provided UUID
        self.id      = uuid
        self.modSym  = sym
        self.caption = nil
        self.symList = []
        self.mfile   = nil
    }
    
    init( from decoder: any Decoder) throws {
        let container = try decoder.container( keyedBy: CodingKeys.self)
        self.id = try container.decode( UUID.self, forKey: .id)
        self.modSym = try container.decode( String.self, forKey: .modSym)
        self.caption = try container.decodeIfPresent( String.self, forKey: .caption)
        self.symList = try container.decode( [SymbolTag].self, forKey: .symList)
    }
    
    static func == ( lhs: MacroFileRec, rhs: MacroFileRec ) -> Bool {
        return lhs.id == rhs.id
    }
}


extension MacroFileRec {
    
    var filename: String {
        "Module.\(modSym).\(id.uuidString)" }
    
    var isModZero: Bool {
        self.modSym == modZeroSym }

    
    func loadModule() -> ModuleFile {
        
        /// ** Load Module **
        
        if let mf = self.mfile {
            
            // Module already loaded
            print( "loadModule: \(mf.modSym) already loaded" )
            return mf
        }
        
        do {
            let fileURL = Database.moduleDirectoryURL().appendingPathComponent( self.filename )
            let data = try Data( contentsOf: fileURL)
            let store = try JSONDecoder().decode(ModuleStore.self, from: data)
            let mod = store.modFile
            
            print( "loadModule: \(self.modSym) - \(self.id.uuidString) Loaded" )
            
            // Successful load
            self.mfile = mod
            return mod
        }
        catch {
            // Missing file or bad file - create empty file
            print( "Creating Mod file for index: \(self.modSym) - \(self.id.uuidString)")
            
            // Create new module file for mfr rec and save it
            let mod = ModuleFile(self)
            self.mfile = mod
            saveModule()
            return mod
        }
    }

    
    func saveModule() {
        
        /// ** Save Module **
        
        if let mod = self.mfile {
            
            if self.modSym == "_" {
                assert(false)
            }
            
            // Mod file is loaded
            do {
                let store = ModuleStore( mod )
                let data = try JSONEncoder().encode(store)
                let outfile = Database.moduleDirectoryURL().appendingPathComponent( mod.filename )
                try data.write(to: outfile)
                
                print( "saveModule: wrote out: \(mod.filename)")
            }
            catch {
                print( "saveModule: file: \(mod.filename) error: \(error.localizedDescription)")
            }
        }
    }
    
    
    var macroList: [MacroRec] {
        
        /// ** Macro List **
        
        let mf = loadModule()
        return mf.macroTable
    }
    
    
    func deleteAll() {
        
        // Debug use only
        let mf = loadModule()
        self.symList = []
        mf.macroTable = []
        mf.groupTable = []
        saveModule()
    }

    
    func getMacro( _ sTag: SymbolTag ) -> MacroRec? {
        
        /// ** Get Macro **
        
        let mf = loadModule()
        return mf.macroTable.first( where: { $0.symTag == sTag } )
    }
    
    
    func deleteMacro( _ sTag: SymbolTag = SymbolTag(.null) ) {
        
        /// Delete a macro from module with given tag
        /// The null tag is a valid tag for the one allowed Unnamed macro

        let mf = loadModule()
        mf.macroTable.removeAll( where: { $0.symTag == sTag } )
    }
    
    
    func addMacro( _ mr: MacroRec ) {
        
        /// Save macro in module
        let mf = loadModule()

        if let x = mf.macroTable.firstIndex( where: { $0.symTag == mr.symTag } ) {
            
            // Replace existing macro
            mf.macroTable[x] = mr
        }
        else {
            // Add new macro to the end
            mf.macroTable.append(mr)
            
            // Add the symbol to the mfr rec list
            symList.append(mr.symTag)
        }
        
        saveModule()
    }

    
    func setMacroCaption( _ tag: SymbolTag, _ caption: String ) {
        
        /// ** Set Macro Caption **
        
        if let mr = getMacro(tag) {
            
            // Change caption and save
            mr.caption = caption
            saveModule()
        }
        else {
            // Non-existant macro
            assert(false)
        }
    }
    
    
    func changeMacroTag( from oldTag: SymbolTag, to newTag: SymbolTag ) {
        
        if let mr = getMacro(oldTag) {
            
            // TODO: check for newTag already in use
            
            // Macro exists - change tag
            mr.symTag = newTag
            
            if let x = self.symList.firstIndex( of: oldTag ) {
                
                // Update symbol list in mfr rec
                self.symList[x] = newTag
            }
            else {
                // Sym is missing, add it
                self.symList.append(newTag)
                assert(false)
            }
                
            saveModule()
        }
        else {
            // Non-existant macro
            assert(false)
        }
    }
}


// ********************************************************* //

/// ** State File **

class StateFile: Codable {
    
    /// One of these files per calculator state
    
    var state:     CalcState
    var unitData:  UserUnitData
    var keyMap:    KeyMapRec
}


/// ** State File Record **

final class StateFileRec: Codable {
    
    var id: UUID
    var caption: String?
    
    // Not stored in state file - nil if file not loaded
    var sfile: StateFile?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case caption
        // Ignore sfile for Codable
    }
    
}


// ********************************************************* //

class IndexFile: Codable {
    
    /// Only one of these tables per app
    /// Contains a record of each macro library file
    
    var stateTable: [StateFileRec] = []
    var mfileTable: [MacroFileRec] = []
}


let modZeroSym = "mod0"


class Database {
    
    var indexFile: IndexFile = IndexFile()
}


extension Database {
    
    func getMacroFileRec( sym: String ) -> MacroFileRec? {
        indexFile.mfileTable.first( where: { $0.modSym == sym } )
    }
    
    func getMacroFileRec( id: UUID ) -> MacroFileRec? {
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
            
            guard let _ = addExistingMacroFile( symbol: modName, uuid: modUUID) else {
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

    
    func createModZero() -> MacroFileRec {
        
        /// ** Create the Zero Module **
        
        if let mod0 = getMacroFileRec( sym: modZeroSym ) {
            
            // Module zero already exists
            print( "createModZero: Already exists" )
            return mod0
        }
        
        guard let mod0 = createNewMacroFile( symbol: modZeroSym) else {
            print( "createModZero: Failed to create Mod zero" )
            assert(false)
        }
        
        print( "createModZero: Created" )
        return mod0
    }
    
    // **********

    
    func loadModule( _ mfr: MacroFileRec ) -> ModuleFile {
        
        // TODO: Should we eliminate this func
        
        /// ** Load Module **
        return mfr.loadModule()
    }

    
    func saveModule( _ mfr: MacroFileRec ) {
        
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
        let mod0 = createModZero()
        let _ = loadModule(mod0)
    }
    

    // **************

    
    func createNewMacroFile( symbol: String ) -> MacroFileRec? {
        
        /// Create a new module file with unique symbol and a new UUID
        
        if let _ = getMacroFileRec(sym: symbol) {
            // Already exists with this symbol
            return nil
        }
        
        let mfr = MacroFileRec( sym: symbol)
        indexFile.mfileTable.append(mfr)
        
        let modFile = ModuleFile(mfr)
        mfr.mfile = modFile
        
        return mfr
    }

    
    func addExistingMacroFile( symbol: String, uuid: UUID ) -> MacroFileRec? {
        
        /// Create a new module file with unique symbol and a new UUID
        
        if let _ = getMacroFileRec(sym: symbol) {
            // Already exists with this symbol
            return nil
        }
            
        let mfr = MacroFileRec( sym: symbol, uuid: uuid )
        indexFile.mfileTable.append(mfr)
        return mfr
    }
    
    
    func setSymbol( _ mfr: MacroFileRec, to newSym: String ) {
        assert( newSym.count <= 6 && newSym.count > 0 )
        
        
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
        
        // Remove this module from the index
        indexFile.mfileTable.removeAll( where: { $0.modSym == mfr.modSym })
    }
    
    
    func setModuleSymbolandCaption( _ mfr: MacroFileRec, newSym: String, newCaption: String? = nil ) {
        
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
}

