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


struct MacroRec: Codable {
    var symTag:     SymbolTag
    var caption:    String? = nil
    var macro:      MacroOpSeq
}


struct MacroLibrary : Codable {
    // Persistant state of all calculator customization for specific applications
    
    // Definitions of Fn programmable keys
    var macroList: [SymbolTag : MacroRec] = [:]
}


// New code, not yet in service

typealias GroupId = Int

struct MacroRecTable: Codable {
    
    /// One of these files per macro lib group
    
    var id:         UUID
    var caption:    String?
    var groupTable: [UUID]
    var macroTable: [MacroRec]
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
