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

class DocumentFile: Codable {
    
    // Unique ID for this module/file
    var id: UUID = UUID()
    
    // Short name of document
    var docSym: String = ""

    // Descriptive caption for this document
    var caption: String? = nil

    var state:     CalcState
    var unitData:  UserUnitData
    var keyMap:    KeyMapRec
    
    init() {
        self.state = CalcState()
        self.unitData = UserUnitData()
        self.keyMap = KeyMapRec()
    }
    
    init( _ dfr: DocumentFileRec ) {
        
        self.id = dfr.id
        self.docSym = dfr.docSym
        self.caption = dfr.caption
        
        self.state = CalcState()
        self.unitData = UserUnitData()
        self.keyMap = KeyMapRec()
    }
}

extension DocumentFile {
    
    var filename: String {
        "Document.\(docSym).\(id.uuidString)"
    }
}


struct DocumentStore : Codable {
    
    /// DocumentStore
    
    var docFile: DocumentFile
    
    init( _ dFile: DocumentFile = DocumentFile() ) {
        self.docFile = dFile
    }
}


/// ** State File Record **

final class DocumentFileRec: Codable, Identifiable, Equatable {
    
    var id: UUID
    var docSym: String
    var caption: String? = nil
    
    // Not stored in state file - nil if file not loaded
    var dfile: DocumentFile? = nil
    
    private enum CodingKeys: String, CodingKey {
        case id
        case docSym
        case caption
        // Ignore sfile for Codable
    }
    
    init( sym: String ) {
        /// Constuction of a New Empty Document with newly created UUID
        self.id      = UUID()
        self.docSym  = sym
        self.caption = nil
        self.dfile   = nil
    }
    
    init( sym: String, uuid: UUID ) {
        /// Constuction of an existing Document file with provided UUID
        self.id      = uuid
        self.docSym  = sym
        self.caption = nil
        self.dfile   = nil
    }
    
    init( from decoder: any Decoder) throws {
        let container = try decoder.container( keyedBy: CodingKeys.self)
        self.id = try container.decode( UUID.self, forKey: .id)
        self.docSym = try container.decode( String.self, forKey: .docSym)
        self.caption = try container.decodeIfPresent( String.self, forKey: .caption)
    }
    
    static func == ( lhs: DocumentFileRec, rhs: DocumentFileRec ) -> Bool {
        return lhs.id == rhs.id
    }
}


extension DocumentFileRec {
    
    var filename: String {
        "Document.\(docSym).\(id.uuidString)"
    }
    
    var isDocZero: Bool {
        self.docSym == docZeroSym }
    
    
    func loadDocument() -> DocumentFile {
        
        /// ** Load Module **
        
        if let df = self.dfile {
            
            // Module already loaded
            print( "loadDocument: \(df.docSym) already loaded" )
            return df
        }
        
        do {
            let fileURL = Database.moduleDirectoryURL().appendingPathComponent( self.filename )
            let data = try Data( contentsOf: fileURL)
            let store = try JSONDecoder().decode( DocumentStore.self, from: data)
            let doc = store.docFile
            
            assert( self.id == doc.id && self.docSym == doc.docSym )
            
            print( "loadModule: \(self.docSym) - \(self.id.uuidString) Loaded" )
            
            // Successful load
            self.dfile = doc
            return doc
        }
        catch {
            // Missing file or bad file - create empty file
            print( "Creating Doc file for index: \(self.docSym) - \(self.id.uuidString)")
            
            // Create new module file for mfr rec and save it
            let doc = DocumentFile(self)
            self.dfile = doc
            saveDocument()
            return doc
        }
    }

    
    func saveDocument() {
        
        /// ** Save Document **
        
        if let doc = self.dfile {
            
            assert( self.docSym != "_" )
            assert( self.docSym == doc.docSym && self.caption == doc.caption )
            
            // Mod file is loaded
            do {
                let store = DocumentStore( doc )
                let data = try JSONEncoder().encode(store)
                let outfile = Database.moduleDirectoryURL().appendingPathComponent( doc.filename )
                try data.write(to: outfile)
                
                print( "saveModule: wrote out: \(doc.filename)")
            }
            catch {
                print( "saveModule: file: \(doc.filename) error: \(error.localizedDescription)")
            }
        }
    }
}

