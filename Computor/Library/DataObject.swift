//
//  DataObject.swift
//  Computor
//
//  Created by Barry Hall on 2025-09-22.
//

import SwiftUI


protocol DataObjectProtocol: AnyObject, Identifiable, Equatable, CustomStringConvertible {
    
    // Stored properties required
    var id: UUID { get }
    var name: String { get set }
    var caption: String? { get set }
}


// ***************************************************************************** Data Object File
// ***************************************************************************** Data Object File
// ***************************************************************************** Data Object File

class DataObjectFile: DataObjectProtocol, Codable {
    
    // DataObject, Identifiable
    var id: UUID
    var name: String
    var caption: String?

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
    
    static func == ( lhs: DataObjectFile, rhs: DataObjectFile ) -> Bool {
        return lhs.id == rhs.id
    }
}


// ***************************************************************************** Data Object Rec
// ***************************************************************************** Data Object Rec
// ***************************************************************************** Data Object Rec


protocol ObjectRecProtocol: DataObjectProtocol, Codable where FileT: DataObjectFile {
    
    associatedtype FileT
    
    var objFile: FileT? { get set }
    
    init( name: String, caption: String?  )
    init( id: UUID, name: String, caption: String?  )
    
    func saveObject()
    func loadObject() -> FileT
    
    // Computed properties
    var filename: String { get }
    var objectDirectoryURL: URL { get }
}


class DataObjectRec<FileT: DataObjectFile>: ObjectRecProtocol {
    
    // DataObject, Identifiable
    var id: UUID
    var name: String
    var caption: String?
    
    // Not coded
    var objFile: FileT?
    
    var isObjZero: Bool {
        self.name == objZeroName
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case caption
        // objFile not coded
    }

    // DataObject computed properties
    var filename: String { "\(self.objDirName).\(self.name).\(self.id.uuidString)" }
    var objectDirectoryURL: URL { Database.documentDirectoryURL().appendingPathComponent( self.objDirName) }
    
    // CustomStringConvertible
    var description: String { "\(self.name) - \(self.id.uuidString)" }
    
    required init( name: String, caption: String? = nil ) {
        /// Create a new Object with new UUID
        self.id = UUID()
        self.name = name
        self.caption = caption
        self.objFile = nil
    }

    required init( id uuid: UUID, name: String, caption: String? = nil ) {
        /// Create an existing obj
        self.id = uuid
        self.name = name
        self.caption = caption
        self.objFile = nil
    }
    
    required init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<DataObjectRec<FileT>.CodingKeys> = try decoder.container(keyedBy: DataObjectRec<FileT>.CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: DataObjectRec<FileT>.CodingKeys.id)
        self.name = try container.decode(String.self, forKey: DataObjectRec<FileT>.CodingKeys.name)
        self.caption = try container.decodeIfPresent(String.self, forKey: DataObjectRec<FileT>.CodingKeys.caption)
    }

    var objDirName: String { get {""} }
    var objZeroName: String { get {""} }
    
    static func == ( lhs: DataObjectRec, rhs: DataObjectRec ) -> Bool {
        return lhs.id == rhs.id
    }
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
                
                let outfile = self.objectDirectoryURL.appendingPathComponent( self.filename )
                
                try data.write(to: outfile)
                
                print( "saveObject: wrote out: \(self.filename)")
            }
            catch {
                print( "saveObject: file: \(self.filename) error: \(error.localizedDescription)")
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


// ***************************************************************************** Object Table
// ***************************************************************************** Object Table
// ***************************************************************************** Object Table


// Not needed??
protocol ObjectTableProtocol: Codable {
    associatedtype ObjRecT where ObjRecT: ObjectRecProtocol
    
    var objTable: [ObjRecT]  { get set }
    
}


class ObjectTable<ObjRecT: ObjectRecProtocol> {
    
    typealias TableFile = [ObjRecT]
    
    var tableName: String
    var objZeroName: String
    
    var objTable: [ObjRecT]
    
    func getObjectFileRec( _ name: String ) -> ObjRecT? {
        objTable.first( where: { $0.name == name } )
    }
    
    func getObjectFileRec( id uuid: UUID ) -> ObjRecT? {
        objTable.first( where: { $0.id == uuid } )
    }
    
    init( tableName: String, objZeroName: String = "obj0" ) {
        
        self.tableName = tableName
        self.objZeroName = objZeroName
        objTable = []
    }
    
    var objectDirectoryURL: URL {
        Database.documentDirectoryURL().appendingPathComponent(self.tableName)
    }
    
    var tableFilename: String { "Table.\(self.tableName)" }
    
    
    func splitObjFilename( _ fname: String ) -> ( String, UUID )? {
        
        /// Break down an object filename of form 'TableName.ObjName.UUID'
        
        if !fname.hasPrefix(self.tableName) {
            return nil
        }
        
        let parts = fname.split( separator: ".")
        
        if parts.count < 3 || parts[1].count > 6 {
            return nil
        }
        
        if let uuid = UUID( uuidString: String(parts[2]) ) {
            return (String(parts[1]), uuid)
        }
        
        return nil
    }

    
    func createTableDirectory() {
        
        /// ** Create Table Directory **
        /// Create the 'TableName' subdir under the document directory
        
        createDirectory( self.objectDirectoryURL )
    }

    
    func loadTable() {
        
        /// ** Load Index **
        
        do {
            let fileURL = Database.documentDirectoryURL().appendingPathComponent( self.tableFilename )
            let data    = try Data( contentsOf: fileURL)
            
            objTable = try JSONDecoder().decode( TableFile.self, from: data)
        }
        catch {
            // File not found - Return an empty Index
            objTable = []
        }
    }
    
    
    
    func saveTable() {
        
        /// ** Save Table **
        
        do {
            let data = try JSONEncoder().encode(objTable)
            let outfile = Database.documentDirectoryURL().appendingPathComponent( self.tableFilename )
            try data.write(to: outfile)
            
            print( "Save Table: ../\( findPathTail(outfile.path(), from: "Documents" ) )" )
        }
        catch {
            print( "Save Table: Error - \(error.localizedDescription)")
        }
    }

    
    // ************************************************
    // ************************************************
    // ************************************************

    
    func syncModules() {
        
        /// ** Sync Modules **
        /// Make Index file consistent with actual module files present
        
        print( "\nSync: \(self.tableName) Objects:" )
        
        let modDir = self.objectDirectoryURL
        
        let modFilenameList = listFiles( inDirectory: modDir.path(), withPrefix: "\(self.tableName).")
        
        var validModFiles: [(String, UUID)] = modFilenameList.compactMap { fname in splitObjFilename(fname) }
        
        var missingFiles: [UUID] = []
        
        var mod0IdList: [UUID] = validModFiles.compactMap( { (sym, uuid) in sym == objZeroName ? uuid : nil } )
        
#if DEBUG
        print("#1 \(self.tableName) filename list:")
        for fn in modFilenameList {
            print( "   found: \(fn)" )
        }
        print("")
        
        print("#2 Valid files found:")
        for (name, uuid) in validModFiles {
            print( "   \(name) - \(uuid.uuidString)" )
        }
        print("")
        
        if mod0IdList.count > 1 {
            print("Multiple \(self.objZeroName) files")
            for id in mod0IdList {
                print( "   \(self.objZeroName) - \(id.uuidString)" )
            }
        }
#endif
        
        var numMatched = 0
        
        var mfrMod0: ObjRecT? = nil
        
        // For each record in the index file
        for mfr in objTable {
            
            if let (modName, modUUID) = validModFiles.first( where: { (name, uuid) in uuid == mfr.id } ) {
                
                // The file exists
                
                if modName != mfr.name {
                    // Should not happen - correct index
                    assert(false)
                    mfr.name = modName
                }
                
                print( "   \(self.tableName) file match: \(modName) - \(modUUID.uuidString)" )
                numMatched += 1
                
                if modName == modZeroSym {
                    // Enforce only one mod0
                    assert( mfrMod0 == nil )
                    mfrMod0 = mfr
                    
                    // Remove the mod0 file id that matches Index
                    mod0IdList.removeAll(where: { $0 == mfr.id } )
                }
                
                validModFiles.removeAll( where: { (name, uuid) in uuid == mfr.id } )
            }
            else {
                // No file matching this index entry
                missingFiles.append(mfr.id)
                
                print( "   Missing \(tableName) file for index entry: \(mfr.name) - \(mfr.id.uuidString)")
            }
        }
        
        print( "   Number of matched files(\(numMatched)), remaining valid(\(validModFiles.count)), index entries(\(objTable.count))" )
        
        // Eliminate index file entries where the file is missing
        objTable.removeAll( where: { missingFiles.contains( $0.id ) } )
        
        print( "   Remaining index entries after removing missing files(\(objTable.count))")
        
        // Add index entries for remaining valid files
        for (modName, modUUID) in validModFiles {
            
            if let _ = mfrMod0 {
                if modName == objZeroName {
                    
                    // Don't add a 2nd Index for extra mod0 file
                    continue
                }
            }
            
            print("   Adding \(self.tableName) ObjectRec for: \(modName) - \(modUUID.uuidString)")
            
            guard let _ = addExistingObjectFile( name: modName, uuid: modUUID) else {
                // assert(false)
                print( "   Obj: \(modName) - \(modUUID) conflict with existing module with same name" )
                return
            }
        }
        
        if !validModFiles.isEmpty || !missingFiles.isEmpty {
            // Write out index file since we added or removed entries to it
            saveTable()
        }
        
        // Delete any extraneous obj0 files
        if mod0IdList.count > 0 {
            for uuid in mod0IdList {
                deleteFile( fileName: "\(tableName).\(objZeroName).\(uuid.uuidString)", inDirectory: modDir )
            }
        }
    }
    
    
    func getObjZero() -> ObjRecT {
        
        /// ** Create the Zero Object **
        
        if let obj0 = getObjectFileRec( objZeroName ) {
            
            // Object zero already exists
            print( "createObjZero: Already exists" )
            return obj0
        }
        
        guard let obj0 = createNewObject( name: objZeroName ) else {
            print( "createObjZero: Failed to create Obj zero" )
            assert(false)
        }
        
        print( "createObjZero: Created obj0 - \(obj0.id.uuidString)" )
        return obj0
    }
    
    
    func loadObjectLibrary() {
        
        /// ** Load Library **
        
        print( "\nLoad Object Library: \(self.tableName)" )
        
        createTableDirectory()
        loadTable()
        syncModules()
        
        // Create Module zero if it doesn't exist and load it
        let obj0 = getObjZero()
        let _ = loadObject(obj0)
    }

    
    // ************************************************
    // ************************************************  Object Functions
    // ************************************************

    
    func createNewObject( name: String, caption: String? = nil ) -> ObjRecT? {
        
        /// ** Create New Object File **
        ///     Create a new Object file Index entry with unique symbol and a new UUID
        ///     Don't create a DocumentFile until needed
        
        if let _ = getObjectFileRec(name) {
            
            // Object already exists with this symbol
            return nil
        }
        
        let rec = ObjRecT( name: name, caption: nil)
        
        // This will create an object file if needed
        _ = rec.loadObject()
        
        // Add to Index and save
        objTable.append(rec)
        saveTable()
        return rec
    }
    
    
    func addExistingObjectFile( name: String, uuid: UUID ) -> ObjRecT? {
        
        /// ** Add Existing Object File **
        ///     Create a new module file with unique symbol and a new UUID
        
        if let _ = getObjectFileRec(name) {
            // Already exists with this symbol
            return nil
        }
        
        // Create module file index entry
        let rec = ObjRecT( id: uuid, name: name, caption: nil )
        objTable.append(rec)
        
        let mf = rec.loadObject()
        
        // Repair Index if needed
        if mf.name != rec.name || mf.caption != rec.caption {
            assert(false)
            rec.name = mf.name
            rec.caption = mf.caption
            
            // TODO: set symList from module
            saveTable()
        }
        
        return rec
    }
    
    
    func deleteObject( _ rec: ObjRecT ) {
        
        /// ** Delete Object **
        
        // Delete the Object file associated with this rec if it exists
        if let _ = rec.objFile {
            
            // Obj file is loaded
            let objDirURL = self.objectDirectoryURL
            deleteFile( fileName: rec.filename, inDirectory: objDirURL )
            rec.objFile = nil
        }
        else {
            
            // Mod file is not loaded - delete it anyway
            let objDirURL = self.objectDirectoryURL
            deleteFile( fileName: rec.filename, inDirectory: objDirURL )
        }
        
        // Remove this module from the index
        objTable.removeAll( where: { $0.name == rec.name || $0.id == rec.id })
        saveTable()
    }
    
    
    func setObjectNameAndCaption( _ rec: ObjRecT, newName: String, newCaption: String? = nil ) {
        
        /// ** Set Object Symbol and Caption **
        
        // Load the object file
        let obj = loadObject(rec)
        
        let nameChanged = newName != rec.name
        
        if nameChanged {
            // Original obj URL
            let objURL = Database.moduleDirectoryURL().appendingPathComponent( rec.filename )
            
            rec.name = newName
            obj.name = newName
            
            renameFile( originalURL: objURL, newName: rec.filename)
        }
        
        rec.caption = newCaption
        obj.caption = newCaption
        
        saveObject(rec)
        saveTable()
    }

    
    func loadObject( _ rec: ObjRecT ) -> ObjRecT.FileT {
        
        // TODO: Should we eliminate this func
        
        /// ** Load Module **
        return rec.loadObject()
    }
    
    
    func saveObject( _ rec: ObjRecT ) {
        
        // TODO: Should we eliminate this func
        
        /// ** Save Module **
        rec.saveObject()
    }
    
}
