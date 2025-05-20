//
//  DataStore.swift
//  Computor
//
//  Created by Barry Hall on 2025-05-20.
//
import SwiftUI


extension CalculatorModel {
    
    struct ConfigStore : Codable {
        /// ConfigStore
        /// Long term configuration data such as Fn key definitions
        /// File updated immediately when calculator configuration is changed
        
        var appConfig: ApplicationConfig
        
        init( _ appC: ApplicationConfig = ApplicationConfig() ) {
            self.appConfig = appC
        }
    }
    
    struct DataStore : Codable {
        var state:    CalcState
        var unitDefs: [UserUnitDef]
        var typeDefs: [UserTypeDef]
        
        init( _ state: CalcState = CalcState(), _ units: [UserUnitDef] = [], _ types: [UserTypeDef] = [] ) {
            self.state = state
            self.unitDefs = units
            self.typeDefs = types
        }
    }
    
    private static func configFileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("computor.config")
    }

    private static func stateFileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("computor.state")
    }
    
    func loadConfig() async throws {
        let task = Task<ConfigStore, Error> {
            let fileURL = try Self.configFileURL()
            
            guard let data = try? Data( contentsOf: fileURL) else {
                return ConfigStore()
            }
            
            let config = try JSONDecoder().decode(ConfigStore.self, from: data)
            return config
        }
        
        let store = try await task.value
        
        Task { @MainActor in
            // Update the @Published property here
            self.appState = store.appConfig
        }
    }

    func loadState() async throws {
        let task = Task<DataStore, Error> {
            let fileURL = try Self.stateFileURL()
            
            guard let data = try? Data( contentsOf: fileURL) else {
                return DataStore()
            }
            
            let state = try JSONDecoder().decode(DataStore.self, from: data)
            return state
        }
        
        let store = try await task.value
        
        Task { @MainActor in
            // Update the @Published property here
            UnitDef.userUnitDefs = store.unitDefs
            TypeDef.userTypeDefs = store.typeDefs
            self.state = store.state

            UnitDef.redefineUserUnits()
            TypeDef.redefineUserTypes()
        }
    }
    
    func saveConfig() async throws {
        /// Save configuration immediately after a change
        /// Don't wait for app termination
        
        let task = Task {
            let store = ConfigStore( appState )
            let data = try JSONEncoder().encode(store)
            let outfile = try Self.configFileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
    
    func saveConfiguration() {
        
        Task {
            do {
                try await saveConfig()
            }
            catch {
                fatalError(error.localizedDescription)
            }
        }
    }

    func saveState() async throws {
        /// Save calculator state when app terminates
        
        let task = Task {
            let store = DataStore( state, UnitDef.userUnitDefs, TypeDef.userTypeDefs )
            let data = try JSONEncoder().encode(store)
            let outfile = try Self.stateFileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }

}
