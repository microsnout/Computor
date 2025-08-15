//
//  DataStore.swift
//  Computor
//
//  Created by Barry Hall on 2025-05-20.
//
import SwiftUI


extension CalculatorModel {
    
    func loadLibrary() async {
        
        do {
            try await createModuleDirectory()
            
            await loadIndex()
            await syncModules()
            
            try await loadModules()
            
            try await loadState()
            
            listDocuments()
        }
        catch {
            print( "File load error: \(error.localizedDescription)" )
        }
    }
    
    struct IndexStore : Codable {
        /// IndexStore
        /// List of other data files, macro and state files
        ///
        
        var indexFile: ComputorIndexFile
        
        init( _ iFile: ComputorIndexFile = ComputorIndexFile() ) {
            self.indexFile = iFile
        }
    }

    struct ConfigStore : Codable {
        /// ConfigStore
        /// Long term configuration data such as Fn key definitions
        /// File updated immediately when calculator configuration is changed
        
        var macroLib: ModuleFile
        
        init( _ appC: ModuleFile = ModuleFile() ) {
            self.macroLib = appC
        }
    }
    
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
    
    private static func indexFileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("computor.index")
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

    private static func moduleDirectoryURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("Module")
    }

    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls( for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    
    func createModuleDirectory() async throws {
        
        let modDirURL = try Self.moduleDirectoryURL()
        
        do {
            try FileManager.default.createDirectory( at: modDirURL, withIntermediateDirectories: false, attributes: nil)
            
            print("Directory created successfully at: \(modDirURL.path)")
        }
        catch CocoaError.fileWriteFileExists {
            print( "File Already Exists" )
        }
        catch {
            print("Error creating directory: \(error.localizedDescription)")
        }
    }
    
    
    func listFiles( inDirectory path: String, withPrefix pattern: String ) -> [String] {
        
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            let filteredFiles = contents.filter { $0.hasPrefix(pattern) }
            return filteredFiles
        }
        catch {
            print("Error listing directory contents: \(error)")
            return []
        }
    }
    
    
    func listDocuments() {
        
        let url   = getDocumentsDirectory()
        let files = listFiles( inDirectory: url.path(), withPrefix: "Module" )
        
        for f in files {
            print("DocFile: \(f)")
        }
    }
    
    
    func loadIndex() async {
        
        let task = Task<IndexStore, Error> {
            let fileURL = try Self.indexFileURL()
            let data    = try Data( contentsOf: fileURL)
            let index   = try JSONDecoder().decode( IndexStore.self, from: data)
            return index
        }
        
        var iFile: ComputorIndexFile
        
        do {
            // Try to load file Computor.Index
            let store = try await task.value
            iFile = store.indexFile
        }
        catch {
            // File not found - Return an empty Index
            iFile = ComputorIndexFile()
            print( "Index file not found - using empty file" )
        }

        Task { @MainActor in
            self.libRec.index = iFile
        }
    }
    
    
    func syncModules() async {
        
        do {
            let modDir = try Self.moduleDirectoryURL()
            
            let modFiles = listFiles(inDirectory: modDir.path(), withPrefix: "Module")
            
            print( "syncModules:" )
            for f in modFiles {
                print( "  file: \(f)" )
            }
            print("")
        }
        catch {
            print("Error listing module directory contents: \(error)")
        }
        
    }

    
    func loadModules() async throws {
        
        let task = Task<ConfigStore, Error> {
            let fileURL = try Self.configFileURL()
            
            guard let data = try? Data( contentsOf: fileURL) else {
                return ConfigStore()
            }
            
            let config = try JSONDecoder().decode(ConfigStore.self, from: data)
            return config
        }
        
//        let store = ConfigStore()
        let store = try await task.value

        Task { @MainActor in
            // Update the @Published property here
            self.macroMod = store.macroLib
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
        
//        let store = DataStore()
        let store = try await task.value

        Task { @MainActor in
            // Update the @Published property here
            UserUnitData.uud = store.unitData
            self.state = store.state
            self.kstate.keyMap = store.keyMap

            UnitDef.reIndexUserUnits()
            TypeDef.reIndexUserTypes()
        }
    }
    
    func saveConfig() async throws {
        /// Save configuration immediately after a change
        /// Don't wait for app termination
        
        let task = Task {
            let store = ConfigStore( macroMod )
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
            let store = DataStore( state, UserUnitData.uud, kstate.keyMap )
            let data = try JSONEncoder().encode(store)
            let outfile = try Self.stateFileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }

}
