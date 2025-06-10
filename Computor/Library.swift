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
    var opSeq:      MacroOpSeq
}


// New code, not yet in service

typealias GroupId = Int

struct MacroRecTable: Codable {
    
    /// One of these files per macro lib group
    
    var id:         UUID = UUID()
    var caption:    String? = nil
    var groupTable: [UUID] = []
    var macroTable: [MacroRec] = []
}

extension MacroRecTable {
    
    func getMacro( _ sTag: SymbolTag ) -> MacroRec? {
        for mr in self.macroTable {
            if mr.symTag == sTag {
                return mr
            }
        }
        return nil
    }
    
    mutating func clearMacro( _ sTag: SymbolTag ) {
        self.macroTable.removeAll( where: { $0.symTag == sTag } )
    }
    
    mutating func setMacro( _ sTag: SymbolTag, _ mr: MacroRec ) {
        
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
