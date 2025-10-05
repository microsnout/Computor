//
//  Database.swift
//  Computor
//
//  Created by Barry Hall on 2025-06-07.
//
import SwiftUI


let modZeroSym = "mod0"
let docZeroSym = "doc0"


// ********************************************************* //


class Database {
    
    var docTable = ObjectTable<DocumentRec>( tableName: "Computor", objZeroName: "doc0" )
    
    var modTable = ObjectTable<ModuleRec>( tableName: "Module", objZeroName: "mod0" )
}


extension Database {
    
    func getModuleFileRec( sym: String ) -> ModuleRec? {
        modTable.getObjectFileRec(sym)
    }
    
    func getModuleFileRec( id uuid: UUID ) -> ModuleRec? {
        modTable.getObjectFileRec(id: uuid)
    }
    
    func getDocumentFileRec( name: String ) -> DocumentRec? {
        docTable.getObjectFileRec(name)
    }
    
    func getDocumentFileRec( id uuid: UUID ) -> DocumentRec? {
        docTable.getObjectFileRec(id: uuid)
    }
    
    func getDocZero() -> DocumentRec {
        docTable.getObjZero()
    }
    
    func getModZero() -> ModuleRec {
        modTable.getObjZero()
    }

    
    // *** File system paths ***
    
    static func documentDirectoryURL() -> URL {
        
        try! FileManager.default.url(for: .documentDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: false)
    }
    
    
    // ***************
    
    func loadModule( _ mfr: ModuleRec ) -> ModuleFile {
        
        /// ** Load Module **
        return mfr.loadModule()
    }
    
    
    func saveModule( _ mfr: ModuleRec ) {
        
        /// ** Save Module **
        mfr.saveModule()
    }
    
    
    func loadDatabase() {
        
        /// ** Load Library **
        modTable.loadObjectTable()
        docTable.loadObjectTable()
    }
    
    
    // *****************
    // Library Functions
    
    func createNewModule( symbol: String ) -> ModuleRec? {
        
        /// ** Create New Module File **
        ///     Create a new module file Index entry with unique symbol and a new UUID
        ///     Don't create a ModuleFile until needed
        modTable.createNewObject( name: symbol )
    }
    
    
    func addExistingModuleFile( symbol: String, uuid: UUID ) -> ModuleRec? {
        
        /// ** Add Existing Module File **
        ///     Create a new module file with unique symbol and a new UUID
        modTable.addExistingObjectFile( name: symbol, uuid: uuid )
    }
    
    
    func deleteModule( _ mfr: ModuleRec ) {
        
        /// ** Delete Module **
        modTable.deleteObject(mfr)
    }
    
    
    func setModuleSymbolandCaption( _ mfr: ModuleRec, newSym: String, newCaption: String? = nil ) {
        
        /// ** Set Module Symbol and Caption **
        modTable.setObjectNameAndCaption( mfr, newName: newSym, newCaption: newCaption )
    }
    
    
    func getRemoteSymbolTag( for tag: SymbolTag, to remMod: ModuleRec, from local: ModuleRec? = nil ) -> SymbolTag {
        
        /// ** Get Remote Symbol Tag **
        
        // if local module is not provided, use mod0
        let localMod: ModuleRec = local ?? getModZero()
        
        if remMod == localMod {
            
            // Reference is local - no change to tag
            return tag
        }
        
        // Add this remote id to the local module, create a remote tag
        let modIndex = localMod.getRemoteModuleIndex( for: remMod )
        
        // Create new version of sym tag with mod index added
        let remSym = SymbolTag( tag, mod: modIndex )
        return remSym
    }
    
    
    func getMacro( for tag: SymbolTag, localMod: ModuleRec ) -> (MacroRec, ModuleRec)? {
        
        /// ** Get Macro **
        
        if tag.isLocalTag {
            
            // Lookup tag in local module provided
            if let mr = localMod.getMacro(tag) {
                return (mr, localMod)
            }
            
            return nil
        }
        
        // remTag is local to the remote Mod
        let remTag = tag.localTag
        let modIndex = tag.mod
        
        // Obtain the uuid of the remote module
        if let remModId = localMod.remoteModuleRef( modIndex ) {
            
            // and lookup the module rec
            if let mfrRem = getModuleFileRec(id: remModId) {
                
                // Look for the macro here
                if let mr = mfrRem.getMacro(remTag) {
                    return (mr, mfrRem)
                }
            }
        }
        
        // Bad reference
        return nil
    }
    
    
    func deleteAllMacros() {
        
        /// ** Delete All Macros **  Debug use only
        
        for mfr in modTable.objTable {
            
            if !mfr.isModZero {
                deleteModule(mfr)
            }
        }
        
        let mod0 = getModZero()
        mod0.symList = []
        modTable.saveTable()
        
        let mf0 = mod0.loadModule()
        mf0.macroTable = []
        mf0.groupTable = [mod0.id]
        saveModule(mod0)
    }
    
    
    func deleteMacro( _ sTag: SymbolTag, from mfr: ModuleRec  ) {
        
        /// ** Delete Macro **
        
        // Remove this symbol from the cached symbol list
        mfr.symList.removeAll( where: { $0 == sTag } )
        modTable.saveTable()
        
        mfr.deleteMacro(sTag)
    }
    
    
    func addMacro( _ mr: MacroRec, to mfc: ModuleRec ) {
        
        /// ** Add Macro **
        
        mfc.addMacro(mr)
        modTable.saveTable()
    }
    
    
    func moveMacro( _ mr: MacroRec, from srcMod: ModuleRec, to dstMod: ModuleRec ) {
        
        // Move the existing macro rec
        addMacro( mr, to: dstMod )
        deleteMacro( mr.symTag, from: srcMod )
    }
    
    
    func copyMacro( _ mr: MacroRec, from srcMod: ModuleRec, to dstMod: ModuleRec ) {
        
        // Create a copy of the macro record
        let newMacro = mr.copy()
        addMacro( newMacro, to: dstMod )
    }
    
    
    // **************************
    // *** Document Functions ***
    
    
    func loadDocument( _ dfr: DocumentRec ) -> DocumentFile {
        
        // TODO: Should we eliminate this func
        
        /// ** Load Module **
        return dfr.loadDocument()
    }
    
    
    func saveDocument( _ dfr: DocumentRec ) {
        
        // TODO: Should we eliminate this func
        
        /// ** Save Module **
        dfr.saveDocument()
    }

    func deleteDocument( _ dfr: DocumentRec ) {
        
        /// ** Delete Document **
        docTable.deleteObject(dfr)
    }
    
    
    func createNewDocument( symbol: String, caption: String? = nil ) -> DocumentRec? {
        
        /// ** Create New Document File **
        ///     Create a new Document file Index entry with unique symbol and a new UUID
        ///     Don't create a DocumentFile until needed
        
        docTable.createNewObject(name: symbol, caption: caption)
    }
    
    
    func setDocumentSymbolandCaption( _ dfr: DocumentRec, newSym: String, newCaption: String? = nil ) {
        
        /// ** Set Document Symbol and Caption **
        
        docTable.setObjectNameAndCaption(dfr, newName: newSym, newCaption: newCaption)
    }
    
    func documentExists( _ name: String ) -> Bool {
        if let _ = docTable.getObjectFileRec(name) {
            return true
        }
        return false
    }
}
