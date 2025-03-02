//
//  StateStore.swift
//  Computor
//
//  Created by Barry Hall on 2025-03-01.
//
import SwiftUI

@MainActor
class StateStore: ObservableObject {
    @Published var calcStates: [CalcState] = []
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("computor.state.data")
    }
    
    func load() async throws {
        let task = Task<[CalcState], Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
            }
            
            let states = try JSONDecoder().decode([CalcState].self, from: data)
            return states
        }
        let states = try await task.value
        self.calcStates = states
    }
    
    func save( states: [CalcState]) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(states)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
}

