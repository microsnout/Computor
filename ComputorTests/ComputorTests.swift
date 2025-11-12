//
//  ComputorTests.swift
//  ComputorTests
//
//  Created by Barry Hall on 2024-10-22.
//

import Testing
@testable import Computor



func key( _ kc: KeyCode ) -> MacroOp {
    return MacroEvent( KeyEvent(kc))
}

func lib( _ tag: SymbolTag ) -> MacroOp {
    return MacroEvent( KeyEvent(.lib, mTag: tag) )
}

func real( _ x: Double ) -> MacroOp {
    return MacroValue( tv: TaggedValue( reg: x ) )
}


fileprivate var testSymTable: Set<SymbolTag> = []


func getRandomSymbol() -> SymbolTag {
    
    var sym: SymbolTag = SymbolTag.Null
    
    repeat {
        // Choose random length of symbol
        let len = Int.random( in: 1...3 )
        
        var kcList: [KeyCode] = []
        
        // Generate random list of key codes
        for _ in 1...len {
            let rv = Int.random( in: (KeyCode.symbolCharNull.rawValue+1)...(KeyCode.symbolCharEnd.rawValue-1) )
            let kc = KeyCode( rawValue: rv )
            kcList.append( kc ?? .noop )
        }
        
        sym = SymbolTag( kcList )
        
    } while testSymTable.contains(sym)
            
    testSymTable.insert(sym)
    return sym
}


func withLoadedModel( _ proc: ( _ model: CalculatorModel ) throws -> Void ) throws {
    
    let model = CalculatorModel()
    model.db.loadDatabase()
    try proc(model)
}


func withNewDoc( in model: CalculatorModel, _ proc: ( _ mod: ModuleRec ) throws -> Void ) throws {
    
    let db = model.db
    let modName = Lorem.word
    let caption = Lorem.words(3)
    
    // Delete doc if it exists
    if let mod = db.getModuleFileRec( sym: modName) {
        db.deleteModule(mod)
    }
    
    try #require( db.moduleExists(modName) == false )
    
    let modT = db.createNewModule( symbol: modName, caption: caption )
    
    let mod = try #require(modT)
    
    try proc(mod)
    
    db.deleteModule(mod)
}


func withNewMod( in model: CalculatorModel, _ proc: ( _ mod: ModuleRec ) throws -> Void ) throws {
    
    let db = model.db
    
    let modName = Lorem.word
    let caption = Lorem.words(3)
    
    // Delete module if it exists
    if let mod = db.getModuleFileRec( sym: modName ) {
        db.deleteModule(mod)
    }
    
    try #require( db.moduleExists(modName) == false )
    
    let modT = db.createNewModule( symbol: modName, caption: caption )
    
    let mod = try #require(modT)
    
    try proc(mod)
    
    db.deleteModule(mod)
}


struct ComputorTests {

    @Suite("Basic") struct basicSuite {
        
        
        @Test("Basic Stack Ops") func testStackOps() async throws {
            
            let model = CalculatorModel()
            _ = model.keyPress( KeyEvent( .d5 ) )
            _ = model.keyPress( KeyEvent( .enter ))
            
            #expect( model.state.X == 5.0 )
        }
        
        @Test("Basic Stack Ops 2") func testTwo() async throws {
            
            let model = CalculatorModel()
            _ = model.keyPress( KeyEvent( .d3 ))
            _ = model.keyPress( KeyEvent( .plus ))
            
            #expect( model.state.X == 3.0 )
        }
    }
 
    
    @Suite("Documents") struct documentSuite {
        
        @Test("DocTest1") func testDoc1() throws {
            
            let docName = Lorem.word
            
            let caption = Lorem.words(3)
            
            try withLoadedModel() { model in
                
                let db = model.db
                
                // Delete doc if it exists
                if let doc = db.getModuleFileRec( sym: docName) {
                    db.deleteModule(doc)
                }
                
                try #require( db.moduleExists(docName) == false )
                
                let docT = db.createNewModule( symbol: docName, caption: caption )
                
                let doc = try #require(docT)
                let capStr = try #require(doc.caption)
                
                print( "DocTest1 created document:\(doc.name) caption='\(capStr)'" )
                
                doc.saveModule()
            }
            
            // Persistence test - reload database
            try withLoadedModel() { model in
                
                let db = model.db

                try #require( db.moduleExists(docName) )
                
                if let doc = db.getModuleFileRec( sym: docName) {
                    #expect( doc.name == docName && doc.caption == caption )
                    
                    print( "DocTest1: name=\(docName) caption='\(caption)'")
                    
                    db.deleteModule(doc)
                    
                    try #require( db.moduleExists(docName) == false )
                }
            }
        }
    }
    
    
    @Suite("Modules") struct moduleSuite {
        
        @Test("ModTest1") func testMod1() throws {
            
            try withLoadedModel() { model in
                
                let mod0 = model.db.getModZero()
                
                let s1 = getRandomSymbol()
                
                let m1 = MacroRec( tag: s1 ) + real(3.0) + real(2.0) + key(.plus)
                
                let db = model.db
                
                db.addMacro(m1, to: mod0)
                
                let evt = KeyEvent(.lib, mTag: s1)
                
                _ = model.keyPress(evt)
                
                #expect( model.state.X == 5.0 )
                
                db.deleteMacro(s1, from: mod0)
            }
        }
    }
}
