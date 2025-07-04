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


class MacroRec: Codable {
    var symTag:     SymbolTag
    var caption:    String? = nil
    var opSeq:      MacroOpSeq
    
    init(symTag: SymbolTag, caption: String? = nil, opSeq: MacroOpSeq) {
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
    var id:         UUID = UUID()
    
    // Short name of module - displayed as prefix to symbol
    var modSym: String = "STAT"
    
    // Descriptive caption for this module
    var caption:    String? = nil
    
    // Table of IDs of external referenced modules - array index is encoded in symbols
    var groupTable: [UUID] = []
    
    // List of macro definitions in this module
    var macroTable: [MacroRec] = []
}

extension ModuleFile {
    
    var symStr: String { "{\(self.modSym)}" }
    
    func getMacro( _ sTag: SymbolTag ) -> MacroRec? {
        for mr in self.macroTable {
            if mr.symTag == sTag {
                return mr
            }
        }
        return nil
    }
    
    func clearMacro( _ sTag: SymbolTag ) {
        self.macroTable.removeAll( where: { $0.symTag == sTag } )
    }
    
    func setMacro( _ sTag: SymbolTag, _ mr: MacroRec ) {
        
        if let x = self.macroTable.firstIndex( where: { $0.symTag == sTag } ) {
            // Replace existing macro
            self.macroTable[x] = mr
        }
        else {
            // Add new macro to the end
            self.macroTable.append(mr)
        }
    }
}


struct MacroFileRec: Codable {
    
    /// Description of one macro library file
    /// Contains a list of all symbols defined in file
    
    var id: UUID
    var caption: String?
    var symList: [SymbolTag]
}


struct MacroFileTable: Codable {
    
    /// Only one of these tables per app
    /// Contains a record of each macro library file
    
    var fileTable:  [MacroFileRec]
}
