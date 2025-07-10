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
        
        var macroLib: ModuleFile
        
        var keyMap: KeyMapRec
        
        init( _ appC: ModuleFile = ModuleFile(), _ keyM: KeyMapRec = KeyMapRec() ) {
            self.macroLib = appC
            self.keyMap   = keyM
        }
    }
    
    struct DataStore : Codable {
        var state:    CalcState
        
        var unitData: UserUnitData

        init( _ state: CalcState = CalcState(), _ uud: UserUnitData = UserUnitData() ) {
            self.state = state
            self.unitData = uud
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
            self.macroMod = store.macroLib
            self.kstate.keyMap = store.keyMap
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
            UserUnitData.uud = store.unitData
            self.state = store.state

            UnitDef.reIndexUserUnits()
            TypeDef.reIndexUserTypes()
        }
    }
    
    func saveConfig() async throws {
        /// Save configuration immediately after a change
        /// Don't wait for app termination
        
        let task = Task {
            let store = ConfigStore( macroMod, kstate.keyMap )
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
            let store = DataStore( state, UserUnitData.uud )
            let data = try JSONEncoder().encode(store)
            let outfile = try Self.stateFileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }

}
