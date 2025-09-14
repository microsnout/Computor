//
//  DataStore.swift
//  Computor
//
//  Created by Barry Hall on 2025-05-20.
//
import SwiftUI


extension CalculatorModel {
    

    struct DataStore : Codable {
        var state:    CalcState
        
        var unitData: UserUnitData
        
        var keyMap: KeyMapRec

        init( _ state: CalcState = CalcState(), _ uud: UserUnitData = UserUnitData(), _ keyM: KeyMapRec = KeyMapRec() ) {
            self.state = state
            self.unitData = uud
            self.keyMap   = keyM
        }
    }
    
    
    static func documentDirectoryURL() -> URL {
        
        try! FileManager.default.url(for: .documentDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: false)
    }
    
    private static func stateFileURL() -> URL {
        documentDirectoryURL().appendingPathComponent("computor.state")
    }

    func loadState() {
        
        do {
            let fileURL = Self.stateFileURL()
            let data  = try Data( contentsOf: fileURL)
            let store = try JSONDecoder().decode(DataStore.self, from: data)
            
            // Update the @Published property here
            UserUnitData.uud = store.unitData
            self.state = store.state
            self.kstate.keyMap = store.keyMap
            
            UnitDef.reIndexUserUnits()
            TypeDef.reIndexUserTypes()
        }
        catch {
            print( "State load error: \(error.localizedDescription)" )
        }
    }

    
    func saveState() throws {
        /// Save calculator state when app terminates
        
        let store = DataStore( state, UserUnitData.uud, kstate.keyMap )
        let data = try JSONEncoder().encode(store)
        let outfile = Self.stateFileURL()
        try data.write(to: outfile)
    }
    
    // ***

    
    func saveConfiguration() {
        
        /// ** saveConfiguration **
         
        aux.macroMod.saveModule()
    }

}

