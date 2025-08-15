//
//  Library.swift
//  Computor
//
//  Created by Barry Hall on 2025-06-07.
//
import SwiftUI


struct MemoryRec: Codable {
    var tag:     SymbolTag
    var caption: String? = nil
    var tv:      TaggedValue
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
    var modSym: String = "STAT"
    
    // Descriptive caption for this module
    var caption: String? = nil
    
    // Table of IDs of external referenced modules - array index is encoded in symbols
    var groupTable: [UUID] = []
    
    // List of macro definitions in this module - a macro must have a SymbolTag to be in this list, other fields optional
    var macroTable: [MacroRec] = []
}

extension ModuleFile {
    
    var symStr: String { "{\(self.modSym)}" }
    
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

struct MacroFileRec: Codable, Identifiable {
    
    /// Description of one macro library file
    /// Contains a list of all symbols defined in file
    
    var id: UUID
    var symbol: String
    var caption: String? = nil
    
    // Not stored in Index file - nil if file not loaded
    var mfile: ModuleFile? = nil
    
    private enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case caption
        // Ignore mfile for Codable
    }
}


/// ** State File Record **

struct StateFileRec: Codable {
    
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


struct LibraryRec {
    
    var index: ComputorIndexFile = ComputorIndexFile()
    
    var modList: [ModuleFile] = []
}
