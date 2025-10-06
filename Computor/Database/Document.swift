//
//  Document.swift
//  Computor
//
//  Created by Barry Hall on 2025-09-16.
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
        // TODO: Eventually add UnRow for unit row keys
        fnRow[kc] = tag
    }
    
    // Could add unitRow here
}


// ********************************************************* //

/// ** State File **

class DocumentFile: DataObjectFile {
    
    // Added fields
    var state:     CalcState
    var unitData:  UserUnitData
    var keyMap:    KeyMapRec
    
    private enum CodingKeys: String, CodingKey {
        case state
        case unitData
        case keyMap
    }

    required init() {
        
        self.state    = CalcState()
        self.unitData = UserUnitData()
        self.keyMap   = KeyMapRec()
        
        super.init()
    }
    
    required init( _ obj: any DataObjectProtocol ) {
        
        self.state = CalcState()
        self.unitData = UserUnitData()
        self.keyMap = KeyMapRec()
        
        super.init(obj)
    }
    
    required init( from decoder: any Decoder) throws {
        
        let container = try decoder.container( keyedBy: CodingKeys.self)
        self.state = try container.decode( CalcState.self, forKey: .state)
        self.unitData = try container.decode( UserUnitData.self, forKey: .unitData)
        self.keyMap = try container.decode( KeyMapRec.self, forKey: .keyMap)

        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(state, forKey: .state)
        try container.encode(unitData, forKey: .unitData)
        try container.encode(keyMap, forKey: .keyMap)

        try super.encode(to: encoder)
    }
}


/// ** State File Record **

final class DocumentRec: DataObjectRec<DocumentFile> {
    
    // Added properties
    var dateCreated: Date
    
    private enum CodingKeys: String, CodingKey {
        case dateCreated
    }
    
    required init( name: String, caption: String? = nil ) {
        /// Constuction of a New Empty Document with newly created UUID
        
        self.dateCreated = Date()
         
        super.init( name: name, caption: caption )
    }
    
    required init( id uuid: UUID, name: String, caption: String? = nil ) {
        
        /// Constuction of an existing Document file with provided UUID
        
        self.dateCreated = Date()

        super.init( id: uuid, name: name, caption: caption )
    }
    
    required init( from decoder: any Decoder) throws {
        let container = try decoder.container( keyedBy: CodingKeys.self)
        self.dateCreated = try container.decode( Date.self, forKey: .dateCreated)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dateCreated, forKey: .dateCreated)
        
        try super.encode(to: encoder)
    }
    
    static func == ( lhs: DocumentRec, rhs: DocumentRec ) -> Bool {
        return lhs.id == rhs.id
    }
    
    var isDocZero: Bool {
        self.isObjZero
    }
    
    override var objDirName: String { get {"Computor"} }
    override var objZeroName: String { get {"doc0"} }
}


extension DocumentRec {
    
    func loadDocument() -> DocumentFile {
        
        /// ** Load Module **
        loadObject()
    }

    
    func saveDocument() {
        
        /// ** Save Document **
        saveObject()
    }
    
    
    func readDocument( _ readFunc: (DocumentFile) -> Void ) {
        
        /// ** Read Document **
        
        readObject(readFunc)
    }
    
    
    func writeDocument( _ writeFunc: (DocumentFile) -> Void ) {
        
        /// ** Write Document **
        
        writeObject(writeFunc)
    }
}

