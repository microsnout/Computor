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
        var appState: ApplicationState
        var unitDefs: [UserUnitDef]
        var typeDefs: [UserTypeDef]
        
        init( _ state: CalcState = CalcState(), _ appS: ApplicationState = ApplicationState(), _ units: [UserUnitDef] = [], _ types: [UserTypeDef] = [] ) {
            self.state = state
            self.appState = appS
            self.unitDefs = units
            self.typeDefs = types
        }
    }
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("computor.state")
    }
    
    func loadState() async throws {
        let task = Task<DataStore, Error> {
            let fileURL = try Self.fileURL()
            
            guard let data = try? Data( contentsOf: fileURL) else {
                return DataStore()
            }
            
            let state = try JSONDecoder().decode(DataStore.self, from: data)
            return state
        }
        
        let store = try await task.value
        
        Task { @MainActor in
            // Update the @Published property here
            self.state = store.state
            self.appState = store.appState
            UnitDef.userUnitDefs = store.unitDefs
            TypeDef.userTypeDefs = store.typeDefs
            
            UnitDef.redefineUserUnits()
            TypeDef.redefineUserTypes()
        }
    }
    
    func saveState() async throws {
        let task = Task {
            let store = DataStore( state, appState, UnitDef.userUnitDefs, TypeDef.userTypeDefs )
            let data = try JSONEncoder().encode(store)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }

}
