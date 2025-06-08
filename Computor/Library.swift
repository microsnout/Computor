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
