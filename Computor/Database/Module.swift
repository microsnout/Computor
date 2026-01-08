//
//  Module.swift
//  Computor
//
//  Created by Barry Hall on 2025-09-16.
//
import SwiftUI

@Observable
class MemoryRec: Codable, Identifiable, Hashable, Equatable, TaggedItem {
    var symTag:  SymbolTag
    var caption: String? = nil
    
    var tv:      TaggedValue
    
    // Dependant list - The following list of tags depend on me - all tags must be computed memories
    var dependantList: [SymbolTag] = []
    
    var id: SymbolTag { symTag }
    
    init( tag: SymbolTag, caption: String? = nil, tv: TaggedValue = TaggedValue() ) {
        self.symTag = tag
        self.caption = caption
        self.tv = tv
    }
    
    func getCaption( _ model: CalculatorModel ) -> String {
        
        /// ** Get Caption **
        /// If we are a computed memory, try to get the caption from the associated macro
        
        if symTag.isComputedMemoryTag {
            
            if let macroRec = model.getLocalMacro(symTag) {
                
                return macroRec.caption ?? Const.Placeholder.caption
            }
        }
        
        return caption ?? Const.Placeholder.caption
    }
    
    
    func hash( into hasher: inout Hasher) {
        hasher.combine(symTag)
    }
    
    static func == ( lhs: MemoryRec, rhs: MemoryRec ) -> Bool {
        return lhs.symTag == rhs.symTag
    }
}


@Observable
class MacroRec: Codable, Identifiable, TaggedItem {
    var symTag:     SymbolTag
    var caption:    String? = nil
    
    var opSeq:      MacroOpSeq
    
    var id: SymbolTag { symTag }
    
    var isEmpty: Bool { symTag == SymbolTag.Blank && caption == nil && opSeq.isEmpty }
    
    init(tag symTag: SymbolTag = SymbolTag.Blank , caption: String? = nil, seq opSeq: MacroOpSeq = MacroOpSeq() ) {
        self.symTag = symTag
        self.caption = caption
        self.opSeq = opSeq
    }
    
    func copy() -> MacroRec {
        return MacroRec( tag: self.symTag, caption: self.caption, seq: self.opSeq)
    }
    
    static func +( lhs: MacroRec, rhs: MacroOp ) -> MacroRec {
        // Add a new op to the op seq - used by Testing
        lhs.opSeq.append(rhs)
        return lhs
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
    
    func isAssigned( _ kc: KeyCode ) -> Bool {
        self.tagAssignment(kc) != nil
    }
    
    mutating func clearKeyAssignment( _ kc: KeyCode ) {
        fnRow.removeValue( forKey: kc)
    }
    
    mutating func assign( _ kc: KeyCode, tag: SymbolTag ) {
        fnRow[kc] = tag
    }
}


struct ModuleSettingRec: Codable, Equatable {
    
    var unitSet:   SoftkeyUnits = .mixed
    var navPolar:  Bool = false
}


typealias GroupId = Int


/// **  Module File **

class ModuleFile: DataObjectFile {
    
    // Added fields
    
    // Table of IDs of external referenced modules - array index is encoded in symbols
    var groupTable: [UUID] = [UUID()]
    
    // List of macro definitions in this module - a macro must have a SymbolTag to be in this list
    var macroTable: [MacroRec] = []
    
    // Calculator session state
    var state:     CalcState
    var unitData:  UserUnitData
    var keyMap:    KeyMapRec
    var settings:  ModuleSettingRec
    
    private enum CodingKeys: String, CodingKey {
        case groupTable
        case macroTable
        
        case state
        case unitData
        case keyMap
        case settings
    }
    
    init( _ mfr: ModuleRec ) {
        
        self.groupTable = [mfr.id]
        self.macroTable = []
        self.state = CalcState()
        self.unitData = UserUnitData()
        self.keyMap = KeyMapRec()
        self.settings = ModuleSettingRec()

        super.init()
    }
    
    required init() {
        
        self.groupTable = [UUID()]
        self.macroTable = []
        self.state = CalcState()
        self.unitData = UserUnitData()
        self.keyMap = KeyMapRec()
        self.settings = ModuleSettingRec()

        super.init()
    }
    
    required init( _ obj: any DataObjectProtocol ) {
        
        self.groupTable = [obj.id]
        self.macroTable = []
        self.state = CalcState()
        self.unitData = UserUnitData()
        self.keyMap = KeyMapRec()
        self.settings = ModuleSettingRec()

        super.init(obj)
    }
    
    required init( from decoder: any Decoder) throws {
        
        let container = try decoder.container( keyedBy: CodingKeys.self)
        self.groupTable = try container.decode( [UUID].self, forKey: .groupTable)
        self.macroTable = try container.decode( [MacroRec].self, forKey: .macroTable)
        self.state = try container.decode( CalcState.self, forKey: .state)
        self.unitData = try container.decode( UserUnitData.self, forKey: .unitData)
        self.keyMap = try container.decode( KeyMapRec.self, forKey: .keyMap)
        self.settings = try container.decode( ModuleSettingRec.self, forKey: .settings)

        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(groupTable, forKey: .groupTable)
        try container.encode(macroTable, forKey: .macroTable)
        try container.encode(state,      forKey: .state)
        try container.encode(unitData,   forKey: .unitData)
        try container.encode(keyMap,     forKey: .keyMap)
        try container.encode(settings,   forKey: .settings)

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
        
        log("init decode id=\(id.uuidString) name=[\(name)] symList=\(String(describing: symList))")
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode( symList, forKey: .symList)
        
        try super.encode(to: encoder)
        
        log("encode id=\(id.uuidString) name=[\(name)] symList=\(String(describing: symList))")
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
        
        log("saveModule name=[\(name)] symList=\(String(describing: symList))")
        
        saveObject()
    }
    
    
    func readModule( _ readFunc: (ModuleFile) -> Void ) {
        
        /// ** Read Document **
        
        readObject(readFunc)
    }
    
    
    func writeModule( _ writeFunc: (ModuleFile) -> Void ) {
        
        /// ** Write Document **
        
        writeObject(writeFunc)
    }

    
    var macroList: [MacroRec] {
        
        /// ** Macro List **
        
        let mf = loadModule()
        return mf.macroTable
    }
    
    
    func getLocalMacro( _ tag: SymbolTag ) -> MacroRec? {
        
        /// ** Get Macro **
        
        // A computed memory tag is a macro tag marked as a computed memory
        assert( tag.isLocalTag || tag.isComputedMemoryTag )
        
        // Eliminate the computed memory tag if present
        let sTag = tag.localTag
        
        let mf = loadModule()
        
        if let mr = mf.macroTable.first( where: { $0.symTag == sTag } ) {
            return mr
        }
        
        if sTag == SymbolTag.Modal {
            // Create macro record for modal function recording
            let mr = MacroRec( tag: sTag, caption: "Modal" )
            addMacro(mr)
            return mr
        }
        
        return nil
    }
    
    
    func deleteMacro( _ sTag: SymbolTag ) {
        
        /// ** Delete Macro **
        ///     Delete a macro from module with given tag
        ///     The null tag is a valid tag for the one allowed Unnamed macro
        
        log("deleteMacro \(String(describing: sTag))")
        
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
    
    
    func changeMacroCaption( _ tag: SymbolTag, _ caption: String ) {
        
        /// ** Change Macro Caption **
        
        if let mr = getLocalMacro(tag) {
            
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
        
        log( "changeMacroTag from[\(String(describing: oldTag))] to[\(String(describing: newTag))]" )
        
        if let mr = getLocalMacro(oldTag) {
            
            // TODO: check for newTag already in use
            
            // Macro exists - change tag
            mr.symTag = newTag
            
            if let x = self.symList.firstIndex( of: oldTag ) {
                
                // Update symbol list in mfr rec
                self.symList[x] = newTag
                
                log("changeMacroTag update existing")
            }
            else {
                // Sym is missing, add it
                self.symList.append(newTag)
                
                log("changeMacroTag append")
                
                // assert(false)
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

