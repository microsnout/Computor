//
//  Module.swift
//  Computor
//
//  Created by Barry Hall on 2025-09-16.
//
import SwiftUI


protocol TaggedItem {
    var symTag: SymbolTag { get }
    var caption: String? { get }
}


class MacroRec: Codable, Identifiable, TaggedItem {
    var symTag:     SymbolTag
    var caption:    String? = nil
    var opSeq:      MacroOpSeq
    
    var id: SymbolTag { symTag }
    
    var isEmpty: Bool { symTag == SymbolTag.Null && caption == nil && opSeq.isEmpty }
    
    init(tag symTag: SymbolTag = SymbolTag.Null , caption: String? = nil, seq opSeq: MacroOpSeq = MacroOpSeq() ) {
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

class ModuleFile: DataObjectFile {
    
    // Added fields
    
    // Table of IDs of external referenced modules - array index is encoded in symbols
    var groupTable: [UUID] = [UUID()]
    
    // List of macro definitions in this module - a macro must have a SymbolTag to be in this list
    var macroTable: [MacroRec] = []
    
    private enum CodingKeys: String, CodingKey {
        case groupTable
        case macroTable
    }
    
    init( _ mfr: ModuleRec ) {
        
        self.groupTable = [mfr.id]
        self.macroTable = []
        
        super.init()
    }
    
    required init() {
        
        self.groupTable = [UUID()]
        self.macroTable = []
        
        super.init()
    }
    
    required init( _ obj: any DataObjectProtocol ) {
        
        self.groupTable = [obj.id]
        self.macroTable = []
        
        super.init(obj)
    }
    
    required init( from decoder: any Decoder) throws {
        
        let container = try decoder.container( keyedBy: CodingKeys.self)
        self.groupTable = try container.decode( [UUID].self, forKey: .groupTable)
        self.macroTable = try container.decode( [MacroRec].self, forKey: .macroTable)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(groupTable, forKey: .groupTable)
        try container.encode(macroTable, forKey: .macroTable)
        
        try super.encode(to: encoder)
    }
}


// ********************************************************* //

/// ** Module Record **

final class ModuleRec: DataObjectRec<ModuleFile> {
    
    /// Description of one macro library file
    /// Contains a list of all symbols defined in file
    
    // Added fields
    var symList: [SymbolTag] = []
    
    // Not stored in file - nil if file not loaded
    var mfile: ModuleFile? = nil
    
    private enum CodingKeys: String, CodingKey {
        case symList
        // Ignore mfile for Codable
    }
    
    required init( name: String, caption: String? = nil ) {
        /// Constuction of a New Empty Module with newly created UUID
        self.symList = []
        self.mfile   = nil
        
        super.init( name: name, caption: caption)
    }
    
    required init( id uuid: UUID, name: String, caption: String? = nil ) {
        /// Constuction of an existing Module file with provided UUID
        self.symList = []
        self.mfile   = nil
        
        super.init( id: uuid, name: name, caption: caption)
    }
    
    required init( from decoder: any Decoder) throws {
        let container = try decoder.container( keyedBy: CodingKeys.self)
        self.symList = try container.decode( [SymbolTag].self, forKey: .symList)
        
        try super.init( from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode( symList, forKey: .symList)
        
        try super.encode(to: encoder)
    }

    static func == ( lhs: ModuleRec, rhs: ModuleRec ) -> Bool {
        return lhs.id == rhs.id
    }
    
    var isModZero: Bool {
        self.isObjZero }
    
    override var objDirName: String { get {"Module"} }
    override var objZeroName: String { get {"mod0"} }
}


extension ModuleRec {
    
    func loadModule() -> ModuleFile {
        
        /// ** Load Module **
        loadObject()
    }
    
    
    func saveModule() {
        
        /// ** Save Module **
        saveObject()
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
        symList.removeAll( where: { $0 == sTag } )
        
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
    
    
    func getRemoteModuleIndex( for remMfc: ModuleRec ) -> Int {
        
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

