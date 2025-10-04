//
//  Module.swift
//  Computor
//
//  Created by Barry Hall on 2025-09-16.
//
import SwiftUI


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
    
    func copy() -> MacroRec {
        return MacroRec( tag: self.symTag, caption: self.caption, seq: self.opSeq)
    }
}


typealias GroupId = Int


/// **  Module File **

class ModuleFile: Codable {
    
    /// One of these files per macro  module file
    
    // Unique ID for this module/file
    var id: UUID = UUID()
    
    // Short name of module - displayed as prefix to symbol
    var name: String = ""
    
    // Descriptive caption for this module
    var caption: String? = nil
    
    // Table of IDs of external referenced modules - array index is encoded in symbols
    var groupTable: [UUID] = [UUID()]
    
    // List of macro definitions in this module - a macro must have a SymbolTag to be in this list, other fields optional
    var macroTable: [MacroRec] = []
    
    
    init( _ mfr: ModuleFileRec ) {
        self.id = mfr.id
        self.name = mfr.name
        self.caption = mfr.caption
        self.groupTable = [mfr.id]
        self.macroTable = []
    }
    
    init() {
        self.id = UUID()
        self.name = ""
        self.caption = ""
        self.groupTable = [self.id]
        self.macroTable = []
    }
}

extension ModuleFile {
    
    var symStr: String { "{\(self.name)}" }
    
    var filename: String {
        "Module.\(name).\(id.uuidString)"
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

final class ModuleFileRec: Codable, Identifiable, Equatable {
    
    /// Description of one macro library file
    /// Contains a list of all symbols defined in file
    
    var id: UUID
    var name: String
    var caption: String? = nil
    var symList: [SymbolTag] = []
    
    // Not stored in Index file - nil if file not loaded
    var mfile: ModuleFile? = nil
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case caption
        case symList
        // Ignore mfile for Codable
    }
    
    init( sym: String ) {
        /// Constuction of a New Empty Module with newly created UUID
        self.id      = UUID()
        self.name  = sym
        self.caption = nil
        self.symList = []
        self.mfile   = nil
    }
    
    init( sym: String, uuid: UUID ) {
        /// Constuction of an existing Module file with provided UUID
        self.id      = uuid
        self.name  = sym
        self.caption = nil
        self.symList = []
        self.mfile   = nil
    }
    
    init( from decoder: any Decoder) throws {
        let container = try decoder.container( keyedBy: CodingKeys.self)
        self.id = try container.decode( UUID.self, forKey: .id)
        self.name = try container.decode( String.self, forKey: .name)
        self.caption = try container.decodeIfPresent( String.self, forKey: .caption)
        self.symList = try container.decode( [SymbolTag].self, forKey: .symList)
    }
    
    static func == ( lhs: ModuleFileRec, rhs: ModuleFileRec ) -> Bool {
        return lhs.id == rhs.id
    }
}


extension ModuleFileRec {
    
    var filename: String {
        "Module.\(name).\(id.uuidString)" }
    
    var isModZero: Bool {
        self.name == modZeroSym }
    
    
    func loadModule() -> ModuleFile {
        
        /// ** Load Module **
        
        if let mf = self.mfile {
            
            // Module already loaded
            print( "loadModule: \(mf.name) already loaded" )
            return mf
        }
        
        do {
            let fileURL = Database.moduleDirectoryURL().appendingPathComponent( self.filename )
            let data = try Data( contentsOf: fileURL)
            let store = try JSONDecoder().decode(ModuleStore.self, from: data)
            let mod = store.modFile
            
            assert( self.id == mod.id && self.name == mod.name )
            
            print( "loadModule: \(self.name) - \(self.id.uuidString) Loaded" )
            
            // Successful load
            self.mfile = mod
            return mod
        }
        catch {
            // Missing file or bad file - create empty file
            print( "Creating Mod file for index: \(self.name) - \(self.id.uuidString)")
            
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
            
            assert( self.name != "_" )
            assert( self.name == mod.name && self.caption == mod.caption )
            
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
    
    
    func getMacro( _ sTag: SymbolTag ) -> MacroRec? {
        
        /// ** Get Macro **
        
        let mf = loadModule()
        return mf.macroTable.first( where: { $0.symTag == sTag } )
    }
    
    
    func deleteMacro( _ sTag: SymbolTag ) {
        
        /// ** Delete Macro **
        ///     Delete a macro from module with given tag
        ///     The null tag is a valid tag for the one allowed Unnamed macro
        
        let mf = loadModule()
        mf.macroTable.removeAll( where: { $0.symTag == sTag } )
        
        saveModule()
    }
    
    
    func addMacro( _ mr: MacroRec ) {
        
        /// ** Add Macro **
        
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
        
        /// ** Change Macro Tag **
        
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
    
    
    func getRemoteModuleIndex( for remMfc: ModuleFileRec ) -> Int {
        
        /// ** Get Remote Module Index **
        
        let localMod = self.loadModule()
        
        if let index = localMod.groupTable.firstIndex( where: { $0 == remMfc.id } ) {
            
            // The local module already has an entry for this remote
            assert( index >= 1 )
            return index
        }
        
        // Allocate the next available index, add the remote uuid and save local module
        let remIndex = localMod.groupTable.count
        localMod.groupTable.append(remMfc.id)
        self.saveModule()
        
        assert( remIndex >= 1 )
        return remIndex
    }
    
    
    func remoteModuleRef( _ modIndex: Int ) -> UUID? {
        
        /// ** Remote Module Ref **
        
        assert( modIndex >= 1 )
        
        let modFile = self.loadModule()
        
        if modIndex >= modFile.groupTable.count {
            
            // Non-valid reference
            return nil
        }
        
        // Return the uuid of the remote module
        return modFile.groupTable[modIndex]
    }
}

