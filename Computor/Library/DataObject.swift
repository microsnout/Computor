//
//  DataObject.swift
//  Computor
//
//  Created by Barry Hall on 2025-09-22.
//

import SwiftUI


protocol DataObjectProtocol: AnyObject, Identifiable, CustomStringConvertible {
    
    // Stored properties required
    var id: UUID { get }
    var name: String { get set }
    var caption: String? { get set }
    
    // Computed properties
    var filename: String { get }
    var objectDirectoryURL: URL { get }

    // Func requirements
}


class DataObjectFile: DataObjectProtocol, Codable {
    
    // DataObject, Identifiable
    var id: UUID
    var name: String
    var caption: String?
    
    // DataObject computed properties
    var filename: String { "\(self.objDirName).\(self.name).\(self.id.uuidString)" }
    var objectDirectoryURL: URL { Database.documentDirectoryURL().appendingPathComponent( self.objDirName) }

    // CustomStringConvertible
    var description: String { "\(self.name) - \(self.id.uuidString)" }

    required init( _ obj: any DataObjectProtocol ) {
        self.id = obj.id
        self.name = obj.name
        self.caption = obj.caption
    }
    
    required init() {
        self.id = UUID()
        self.name = ""
        self.caption = nil
    }
    
    var objDirName: String { get {""} }
    var objZeroName: String { get {""} }
}


class DataObjectRec<FileT: DataObjectFile>: DataObjectProtocol {
    
    // DataObject, Identifiable
    var id: UUID
    var name: String
    var caption: String?
    
    var objFile: FileT?
    
    // DataObject computed properties
    var filename: String { "\(self.objDirName).\(self.name).\(self.id.uuidString)" }
    var objectDirectoryURL: URL { Database.documentDirectoryURL().appendingPathComponent( self.objDirName) }
    
    // CustomStringConvertible
    var description: String { "\(self.name) - \(self.id.uuidString)" }
    
    init( name: String ) {
        /// Constuction of a New Empty Data Object Rec with newly created UUID
        self.id = UUID()
        self.name = name
        self.caption = nil
        self.objFile = nil
    }
    
    init( name: String, uuid: UUID ) {
        /// Constuction of an existing Document file with provided UUID
        self.id = uuid
        self.name = name
        self.caption = nil
        self.objFile = nil
    }
    
    var objDirName: String { get {""} }
    var objZeroName: String { get {""} }
}


extension DataObjectRec {
    
    var isModZero: Bool {
        self.name == self.objZeroName }
    
    
    func saveObject() {
        
        /// ** Save Object **
        
        if let obj = self.objFile {
            
            assert( self.name != "_" )
            assert( self.name == obj.name && self.caption == obj.caption )
            
            // Object file is loaded
            do {
                let data = try JSONEncoder().encode(obj)
                
                let outfile = self.objectDirectoryURL.appendingPathComponent( obj.filename )
                
                try data.write(to: outfile)
                
                print( "saveObject: wrote out: \(obj.filename)")
            }
            catch {
                print( "saveObject: file: \(obj.filename) error: \(error.localizedDescription)")
            }
        }
    }

    
    func loadObject() -> FileT {
        
        /// ** Load Object **
        
        if let dof = self.objFile {
            
            // Object file already loaded
            print( "loadObject: \(dof.name) already loaded" )
            return dof
        }
        
        do {
            let fileURL = self.objectDirectoryURL.appendingPathComponent( self.filename )
            let data = try Data( contentsOf: fileURL)
            let obj = try JSONDecoder().decode( FileT.self, from: data)
            
            assert( self.id == obj.id && self.name == obj.name )
            
            print( "loadObject: \(self.name) - \(self.id.uuidString) Loaded" )
            
            // Successful load
            self.objFile = obj
            return obj
        }
        catch {
            // Missing file or bad file - create empty file
            print( "Creating Object file for index: \(self.description)" )
            
            // Create new object file for rec and save it
            let dof = FileT(self)
            self.objFile = dof
            saveObject()
            return dof
        }
    }
}



// ***************************************************** Sample

final class SampleObjectFile: DataObjectFile {
    
    static var objectDirectoryName: String { "Sample" }
    static var objectZeroName: String { "Sam0" }
    
    override var objDirName: String { SampleObjectRec.objectDirectoryName }
    override var objZeroName: String { SampleObjectRec.objectZeroName }
}


final class SampleObjectRec: DataObjectRec<SampleObjectFile> {
    
    
    static var objectDirectoryName: String { "Sample" }
    static var objectZeroName: String { "Sam0" }
    
    override var objDirName: String { SampleObjectRec.objectDirectoryName }
    override var objZeroName: String { SampleObjectRec.objectZeroName }
}
