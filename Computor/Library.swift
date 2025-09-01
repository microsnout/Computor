//
//  Library.swift
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
    var modSym: String = "_mod0"
    
    // Descriptive caption for this module
    var caption: String? = nil
    
    // Table of IDs of external referenced modules - array index is encoded in symbols
    var groupTable: [UUID] = []
    
    // List of macro definitions in this module - a macro must have a SymbolTag to be in this list, other fields optional
    var macroTable: [MacroRec] = []
    
    
    init( _ mfr: MacroFileRec ) {
        self.id = mfr.id
        self.modSym = mfr.symbol
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
    
    
    // File Ops
    
    var filename: String {
        "Module.\(modSym).\(id.uuidString)"
    }
    
    // Macro Ops
    
    func getMacro( _ sTag: SymbolTag ) -> MacroRec? {
        
        /// Find a macro in this module from it's symbol tag
        
        for mr in self.macroTable {
            if mr.symTag == sTag {
                return mr
            }
        }
        return nil
    }
    
    
    func deleteMacro( _ sTag: SymbolTag = SymbolTag(.null) ) {
        
        /// Delete a macro from module with given tag
        /// The null tag is a valid tag for the one allowed Unnamed macro
        
        self.macroTable.removeAll( where: { $0.symTag == sTag } )
    }
    
    
    func saveMacro( _ mr: MacroRec ) {
        
        /// Save macro in module
        
        if let x = self.macroTable.firstIndex( where: { $0.symTag == mr.symTag } ) {
            
            // Replace existing macro
            self.macroTable[x] = mr
        }
        else {
            // Add new macro to the end
            self.macroTable.append(mr)
        }
    }
    
    
    func setMacroCaption( _ tag: SymbolTag, _ caption: String ) {
        
        if let mr = getMacro(tag) {
            
            mr.caption = caption
        }
        else {
            // Non-existant macro
            assert(false)
        }
    }
    
    
    func changeMacroTag( from oldTag: SymbolTag, to newTag: SymbolTag ) {
        
        if let mr = getMacro(oldTag) {
            
            // TODO: check for newTag already in use
            
            mr.symTag = newTag
        }
        else {
            // Non-existant macro
            assert(false)
        }
    }
}


/// ** State File **

class StateFile: Codable {
    
    /// One of these files per calculator state
    
    var state:     CalcState
    var unitData:  UserUnitData
    var keyMap:    KeyMapRec
}


/// ** Macro File Record **

class MacroFileRec: Codable, Identifiable {
    
    /// Description of one macro library file
    /// Contains a list of all symbols defined in file
    
    var id: UUID
    var symbol: String
    var caption: String? = nil
    var symbols: [SymbolTag] = []
    
    // Not stored in Index file - nil if file not loaded
    var mfile: ModuleFile? = nil
    
    private enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case caption
        // Ignore mfile for Codable
    }
    
    init( sym: String ) {
        self.id      = UUID()
        self.symbol  = sym
        self.caption = nil
        self.symbols = []
        self.mfile   = nil
    }
}


/// ** State File Record **

class StateFileRec: Codable {
    
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


class ComputorIndexFile: Codable {
    
    /// Only one of these tables per app
    /// Contains a record of each macro library file
    
    var stateTable: [StateFileRec] = []
    var macroTable: [MacroFileRec] = []
}


let modZeroSym = "_mod0"


class Library {
    
    var indexFile: ComputorIndexFile = ComputorIndexFile()
}


extension Library {
    
    func getMacroFileRec( sym: String ) -> MacroFileRec? {
        indexFile.macroTable.first( where: { $0.symbol == sym } )
    }
    
    func getMacroFileRec( id: UUID ) -> MacroFileRec? {
        indexFile.macroTable.first( where: { $0.id == id } )
    }
    
    
    func createNewMacroFile( symbol: String ) -> MacroFileRec? {
        
        /// Create a new module file with unique symbol and a new UUID
        
        if let mfr = getMacroFileRec(sym: symbol) {
            // Already exists with this symbol
            return nil
        }
            
        let mfr = MacroFileRec( sym: symbol)
        indexFile.macroTable.append(mfr)
        indexFile.macroTable.sort( by: { $0.symbol < $1.symbol } )
        
        let modFile = ModuleFile(mfr)
        mfr.mfile = modFile

        return mfr
    }
}
